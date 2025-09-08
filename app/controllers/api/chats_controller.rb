# app/controllers/api/chats_controller.rb
class Api::ChatsController < ApplicationController
  include ActionController::Live  # stream 用
  # protect_from_forgery with: :null_session

  # 設定ロード：uid から最新ActiveのUAVとGSを取る
  def load_generation(uid)
    return [ nil, nil ] if uid.blank?
    uav = UserAgentVersion.latest_active_for_user(uid).first
    gs  = uav&.generation_setting
    [ uav, gs ]
  end

  # build_messages を「DBのinstructions 優先」に変更
  def build_messages(params, uav)
    history = Array(params[:history]).map { |m| { role: m[:role], content: m[:content] } }
    user    = String(params[:message].to_s)

    system_content =
      uav&.instructions.presence || <<~SYS
        あなたは『レゾナンス』の開発補助AI。簡潔・具体・安全に答える。
        （※DBにinstructionsが無い場合のフォールバック）
      SYS

    [ { role: "system", content: system_content },
     *history.last(20),
     { role: "user", content: user } ]
  end

  # GS から OpenAI body を合成（存在キーのみ入れる）
  def build_openai_body(model_fallback:, messages:, gs:, stream: false)
    body = {
      model:      gs&.model.presence || model_fallback,
      messages:   messages,
      stream:     stream
    }

    # 数値系
    %i[temperature top_p presence_penalty frequency_penalty seed max_output_tokens].each do |k|
      v = gs&.send(k)
      body[k] = v.to_f if v.present? && k != :seed
      body[k] = v.to_i if v.present? && k == :seed
      body[k] = v.to_i if v.present? && k == :max_output_tokens
    end

  # response_format を正しい形式に変換
  case gs&.response_format
  when "text"
    body[:response_format] = { type: "text" }
  when "json"
    body[:response_format] = { type: "json" }
  when "json_schema"
    if gs&.json_schema_name.present?
      body[:response_format] = { type: "json_schema", name: gs.json_schema_name }
    end
  end

  # reasoning_effort などはサポートされている場合のみ送る
  if gs&.reasoning_effort.present?
    body[:reasoning_effort] = gs.reasoning_effort
  end
    body
  end
  # ---- 非ストリーミング ----
  def create
    uid = params[:uid]
    uav, gs = load_generation(uid)
    messages = build_messages(params, uav)

    # use_stream 指定がDBにあり true なら stream へ誘導してもOK
    # ここは非同期キュー都合で分けておく例
    model_fallback = "gpt-4o-mini"
    body = build_openai_body(model_fallback: model_fallback, messages: messages, gs: gs, stream: false)

    resp = Faraday.post("https://api.openai.com/v1/chat/completions") do |req|
      req.headers["Authorization"] = "Bearer #{ENV.fetch("OPENAI_API_KEY")}"
      req.headers["Content-Type"]  = "application/json"
      req.options.timeout = 60
      req.body = body.to_json
    end

    unless resp.success?
      render json: { error: resp.body }, status: resp.status and return
    end

    json  = JSON.parse(resp.body)
    reply = json.dig("choices", 0, "message", "content").to_s

    ConversationLogger.log!(uid: uid, model: body[:model], messages: messages, reply: reply, usage: json["usage"])
    render json: { reply:, usage: json["usage"] }
  end

  # ---- ストリーミング ----
  def stream
    response.headers["Content-Type"]       = "text/event-stream; charset=utf-8"
    response.headers["Cache-Control"]      = "no-cache"
    response.headers["X-Accel-Buffering"]  = "no"

    uid = params[:uid]
    uav, gs = load_generation(uid)
    messages = build_messages(params, uav)

    model_fallback = "gpt-4o-mini"
    body = build_openai_body(model_fallback: model_fallback, messages: messages, gs: gs, stream: true)

    conn = Faraday.new(request: { timeout: 120 }) { |f| f.adapter Faraday.default_adapter }
    upstream = conn.post("https://api.openai.com/v1/chat/completions") do |req|
      req.headers["Authorization"] = "Bearer #{ENV.fetch("OPENAI_API_KEY")}"
      req.headers["Content-Type"]  = "application/json"
      req.body = body.to_json
    end

    if upstream.status != 200
      response.stream.write "data: #{ { error: upstream.body }.to_json }\n\n"
      return
    end

    full_text = +""
    upstream.body.each_line do |line|
      next unless line.start_with?("data:")
      payload = line.delete_prefix("data:").strip
      break if payload == "[DONE]"
      begin
        json = JSON.parse(payload)
        delta = json.dig("choices", 0, "delta", "content").to_s
        full_text << delta
        response.stream.write "data: #{payload}\n\n"
      rescue
      end
    end

    ConversationLogger.log!(uid: uid, model: body[:model], messages: messages, reply: full_text)
  rescue => e
    response.stream.write "data: #{ { error: e.message }.to_json }\n\n"
  ensure
    response.stream.close
  end
end
