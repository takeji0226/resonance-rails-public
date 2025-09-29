# frozen_string_literal: true
class Api::ChatsController < ApplicationController
  before_action :authenticate_user!

  # == POST /api/chat
  # 入力: { uid, message, history? }  ※historyは直近をコンテキストに使うだけ（DB保存はこのメソッド側）
  # 出力: { reply, usage? }
  def create
    user_input = String(params[:message].to_s)
    if user_input.blank?
      render json: { error: "message is blank" }, status: :unprocessable_entity and return
    end

    # 1) OpenAIへ投げるメッセージ組み立て
    messages = build_messages_for_openai(params)

    # 2) OpenAI呼び出し（非ストリーミング）
    reply, usage = call_openai(messages)

    # 3) DB保存（ユーザ発言+アシスタント返信）
    persist_chat!(current_user, user_input, reply)

    render json: { reply:, usage: usage }
  rescue => e
    render json: { error: e.message }, status: 500
  end

  # == GET /api/chat/history
  # 現行(archived=false)の会話を作成/取得し、全メッセージを時系列で返す
  def history
    conv = find_or_create_active_conversation!(current_user)
    rows = conv.chat_messages.order(:created_at)
    # 表示用に user/assistant のみ返す（systemはUIでは省略）
    msgs = rows.where(role: %w[user assistant]).pluck(:id, :role, :content, :created_at)
    render json: {
      conversation_id: conv.id,
      messages: msgs.map { |id, role, content, ts| { id:, role:, content:, created_at: ts } }
    }
  end

  # == POST /api/chat/reset  （任意）
  # 現行会話をarchiveし、新しい空のアクティブ会話を1本作成
  def reset
    ApplicationRecord.transaction do
      Conversation.active_for(current_user).update_all(archived: true)
      Conversation.create!(user: current_user, archived: false)
    end
    head :no_content
  end

  private

  # ── OpenAI メッセージ構築（直近のhistoryを最大20件まで活用）
  def build_messages_for_openai(params)
    history = Array(params[:history]).map { |m| { role: m[:role], content: m[:content] } }
    user    = String(params[:message].to_s)

    system_content = <<~SYS
      あなたは『レゾナンス』の開発補助AIです。簡潔・具体・安全に回答してください。
    SYS

    [ { role: "system", content: system_content },
      *history.last(20),
      { role: "user", content: user } ]
  end

  # ── OpenAI 呼び出し（最低限の非ストリーミング実装）
  def call_openai(messages)
    body = {
      model: "gpt-4o-mini",
      messages: messages,
      stream: false
    }

    resp = Faraday.post("https://api.openai.com/v1/chat/completions") do |req|
      req.headers["Authorization"] = "Bearer #{ENV.fetch("OPENAI_API_KEY")}" # ← 末尾の)に注意
      req.headers["Content-Type"]  = "application/json"
      req.options.timeout = 60
      req.body = body.to_json
    end

    raise "upstream #{resp.status}" unless resp.success?

    json  = JSON.parse(resp.body)
    reply = json.dig("choices", 0, "message", "content").to_s
    usage = json["usage"]
    [reply, usage]
  end

  # ── 会話作成/取得（ユニーク制約に伴うレースハンドリング）
  def find_or_create_active_conversation!(user)
    Conversation.active_for(user).first || Conversation.create!(user: user, archived: false)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  # ── 保存
  def persist_chat!(user, user_input, assistant_reply)
    conv = find_or_create_active_conversation!(user)
    Conversation.transaction do
      conv.touch
      conv.chat_messages.create!(role: "user",      content: user_input)
      conv.chat_messages.create!(role: "assistant", content: assistant_reply)
    end
  end
end
