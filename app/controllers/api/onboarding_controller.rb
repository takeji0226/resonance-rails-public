# app/controllers/api/onboarding_controller.rb
class Api::OnboardingController < ApplicationController
  before_action :authenticate_user!

  require_dependency 'onboarding_nlp_service'
  require_dependency 'llm/openai_client'

  # -----------------------------------------------------
  # GET /api/onboarding/status
  # 現在のオンボーディング進捗を返す。
  # 例: { stage: "pebble", cycles_done: 1, cycles_target: 4 }
  # -----------------------------------------------------
  def status
    session = current_user.onboarding_sessions.order(created_at: :desc).first
    render json: {
      stage: current_user.onboarding_stage || "none",
      cycles_done: session&.cycles_done || 0,
      cycles_target: session&.cycles_target || 0
    }
  end

  # -----------------------------------------------------
  # POST /api/onboarding/start
  # 新しいオンボーディングセッションを開始。
  # ・サーバ側で cycles_target を 3〜5 から決定
  # ・ユーザの onboarding_stage を "pebble" に更新（初回のみ）
  # 例: { session_id: 12, cycles_target: 4 }
  # -----------------------------------------------------
  def start
    target = rand(3..5)
    session = current_user.onboarding_sessions.create!(
      stage: "pebble",
      cycles_target: target,
      cycles_done: 0
    )
    # まだ何も設定されていない初回ユーザならステージを進める
    if current_user.onboarding_stage.nil? || current_user.onboarding_stage == "none"
      current_user.update!(onboarding_stage: "pebble", first_login_at: Time.current)
    end
    render json: { session_id: session.id, cycles_target: target }
  end

  # -----------------------------------------------------
  # POST /api/onboarding/pebble
  # DB(initial_questions)からランダムに1問返す。
  # 【変更点】
  # - フロントが後続の /reply で返せるよう、question_id を必ず返す。
  # 例: { question_id: 42, question: "あなたが最近大事にした小さな選択は？" }
  # -----------------------------------------------------
  def pebble
    q = InitialQuestion.where(active: true).order("RANDOM()").first
    render json: {
      question_id: q&.id,                    # ★追加
      question: q&.body || "（初期問いが未登録です）"
    }
  end

  # -----------------------------------------------------
  # POST /api/onboarding/reply
  # ユーザ返答を受け取り、保存して進捗を更新。
  # 【変更点】
  # - initial_question_id 未送信時、history の全 assistant 発話を後方から走査して
  #   InitialQuestion を逆引き（完全一致→部分一致→正規化比較）。
  # - ★ OpenAI 呼び出しを追加（失敗時は既存スタブにフォールバック）
  # -----------------------------------------------------
  def reply
    # 入力
    user_reply = params[:message].to_s.presence || params.dig(:onboarding, :message).to_s

    # 進行中セッション取得
    session = current_user.onboarding_sessions.order(created_at: :desc).first
    return render json: { error: "no session" }, status: :unprocessable_entity unless session

    # 初回の問いIDを取得（フロント優先）
    initial_qid = params[:initial_question_id] || params.dig(:onboarding, :initial_question_id)

    # ★フォールバック強化：history の assistant 発話を「後ろから順」に照合
    if initial_qid.blank?
      history = params[:history] || params.dig(:onboarding, :history) || []
      assistant_texts = history.select { |h| (h["role"] || h[:role]) == "assistant" }
                               .map { |h| h["content"] || h[:content] }
                               .compact
                               .reverse # 末尾（直近）から順に試す

      initial_qid = resolve_initial_question_id_from_texts(assistant_texts)
    end

    # 解決不能なら 422（NOT NULL を守る）
    if initial_qid.blank?
      return render json: { error: "initial_question_id is required (not resolvable from history)" }, status: :unprocessable_entity
    end

    # -------------------------------------------------
    # ★ (1) 抽出：OpenAI → 失敗時はスタブにフォールバック
    # -------------------------------------------------
    extracted =
      begin
        nlp = ::OnboardingNlpService.new
        nlp.extract_focus_points(user_reply)
      rescue => e
        Rails.logger.warn("[OnboardingController] extract via OpenAI failed: #{e.class} #{e.message}")
        nil
      end
    extracted ||= extract_stub(user_reply)

    # --- (2) 角度決定
    angle = decide_angle(session, extracted)

    # --- (3) 返しの型（A/B/C）
    reply_style = decide_style

    # -------------------------------------------------
    # ★ (4) 返信生成：OpenAI → 失敗時はスタブにフォールバック
    # -------------------------------------------------
    assistant_reply =
      begin
        nlp ||= ::OnboardingNlpService.new
        nlp.generate_reply(
          user_reply: user_reply,
          extracted:  extracted,
          angle:      angle,
          style:      reply_style
        )
      rescue => e
        Rails.logger.warn("[OnboardingController] generate via OpenAI failed: #{e.class} #{e.message}")
        nil
      end
    assistant_reply ||= generate_reply_stub(user_reply, extracted, angle, reply_style)

    # ログ保存（NOT NULL 列に必ず値を入れる）
    session.onboarding_exchanges.create!(
      initial_question_id: initial_qid,      # ★必須
      user_reply: user_reply,
      focus_points: extracted,               # [{type:"belief",text:"〜"}...] の配列
      angle: angle,
      reply_style: reply_style,
      assistant_reply: assistant_reply
    )

    # 進捗更新
    session.increment!(:cycles_done)
    session.update!(stage: "looping") if session.stage == "pebble"

    done = session.cycles_done >= session.cycles_target

    render json: {
      assistant_reply: assistant_reply,
      angle: angle,
      reply_style: reply_style,
      done: done
    }
  end

  # -----------------------------------------------------
  # POST /api/onboarding/finish
  # すべてのサイクル終了後のまとめ。
  # -----------------------------------------------------
  def finish
    session = current_user.onboarding_sessions.order(created_at: :desc).first
    return render json: { error: "no session" }, status: :unprocessable_entity unless session

    buckets = { "belief" => [], "like" => [], "strength" => [] }
    session.onboarding_exchanges.find_each do |ex|
      Array(ex.focus_points).each do |fp|
        t = fp.is_a?(Hash) ? fp["type"] : nil
        v = fp.is_a?(Hash) ? fp["text"] : nil
        next unless t && v
        case t
        when "belief"   then buckets["belief"]   << v
        when "like"     then buckets["like"]     << v
        when "strength" then buckets["strength"] << v
        end
      end
    end

    session.update!(
      summary_beliefs:   buckets["belief"].uniq.take(5),
      summary_likes:     buckets["like"].uniq.take(5),
      summary_strengths: buckets["strength"].uniq.take(5),
      stage: "done"
    )
    current_user.update!(onboarding_stage: "done")

    render json: {
      beliefs:   session.summary_beliefs,
      likes:     session.summary_likes,
      strengths: session.summary_strengths
    }
  end

  private

  # ==== 以下は当面のスタブ（OpenAI置換ポイント） ====

  # 抽出スタブ
  def extract_stub(text)
    out = []
    out <<({ "type" => "belief",   "text" => "自分の言葉で考えること" }) if text.length.positive?
    out <<({ "type" => "like",     "text" => "学びの仕組みづくり" })      if text.include?("学")
    out <<({ "type" => "strength", "text" => "構造化して説明する" })        if text.size > 30
    out.take(4)
  end

  # 角度決定（簡易版）
  def decide_angle(session, extracted)
    types = extracted.map { |e| e["type"] }
    return "Contrast" if types.include?("belief")
    return "Depth"    if types.include?("strength")
    return "Breadth"  if types.include?("like")
    rand < 0.33 ? "Timeline" : "Depth"
  end

  # 返しの型（A/B/C）…A多め
  def decide_style
    r = rand
    return "A" if r < 0.65
    return "B" if r < 0.90
    "C"
  end

  # 返信生成スタブ（本番はOpenAI）
  def generate_reply_stub(user_reply, extracted, angle, style)
    prefix =
      case style
      when "A" then "うん、君の言葉がはっきりしてきたね。"
      when "B" then "要するに、君が大事にしているのは「#{(extracted.first || {})['text'] || '今の視点'}」だね。"
      when "C" then "心理学でも、反省的対話が自己理解を深めると言われるよ。"
      else "なるほど。"
      end

    question =
      case angle
      when "Depth" then "もう一段、具体例をひとつ挙げるとしたら何？"
      when "Breadth" then "似た場面で他に当てはまるものはある？"
      when "Contrast" then "逆に、それと反対の考え方をすると何が見える？"
      when "Timeline" then "過去→今→未来の順で、その変化をどう感じてる？"
      else "いま一番しっくり来る一言にすると、どんな言葉？"
      end

    "#{prefix} #{question}"
  end

  # =========================
  # ★ フォールバック解決ヘルパ（最小追加）
  # =========================
  def resolve_initial_question_id_from_texts(assistant_texts)
    return nil if assistant_texts.empty?

    # 1) 完全一致 / 2) ILIKE 先頭30文字 / 3) 正規化（空白・全半角のゆらぎ吸収）でローカル一致
    assistant_texts.each do |text|
      next if text.blank?

      # 1) 完全一致（最速）
      found = InitialQuestion.where(active: true).find_by(body: text)
      return found.id if found

      # 2) ILIKE （誤差吸収、ログのような空白混入に対応）
      head30 = text[0, 30]
      if head30.present?
        ilike = InitialQuestion.where(active: true).where("body ILIKE ?", "%#{head30}%").first
        return ilike.id if ilike
      end
    end

    # 3) 正規化比較（DB→アプリ側で照合。件数が多くない前提の最小実装）
    normalized_cache = {}
    active_questions = InitialQuestion.where(active: true).pluck(:id, :body)
    assistant_texts.each do |text|
      next if text.blank?
      nt = normalized_cache[text] ||= normalize_text(text)
      next if nt.blank?

      match = active_questions.find { |(qid, body)| normalize_text(body) == nt }
      return match.first if match
    end

    nil
  end

  # 空白全除去・全角半角の一部ゆらぎを吸収して比較
  def normalize_text(s)
    return "" if s.nil?
    str = s.to_s
    # 全角スペース含む空白類を除去
    str = str.gsub(/\s+/, "")
    str = str.gsub(/\u3000+/, "")
    # よくある句読点の全半角ゆらぎを軽く吸収
    str = str.tr("，．：；！？」」「『』", ",.:;!?\")(\"")
    str
  end
end
