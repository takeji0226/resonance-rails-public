# frozen_string_literal: true
# app/services/onboarding_nlp_service.rb
# ------------------------------------------------------------
# オンボーディング用の抽出＆返信生成ロジックを集約。
# - extract_focus_points: ユーザ発話から {type,text} の配列を最大4件返す
# - generate_reply: 角度とスタイルを入力として自然文の追い質問を返す
#   ※ OpenAI 障害時はコントローラ側のスタブにフォールバック
# ------------------------------------------------------------

class OnboardingNlpService
  SYSTEM_EXTRACT = <<~SYS
    あなたは短文から信念(belief)・好き(like)・強み(strength)を抽出するアシスタントです。
    出力は JSON 配列のみ。各要素は { "type": "belief|like|strength", "text": "..." }。
    最大4件、本文をそのまま短句で。余計な説明や前置きは一切不要。
  SYS

  SYSTEM_REPLY = <<~SYS
    あなたは内省を促すコーチです。ユーザの返答を受けて、指定された角度(angle)とスタイル(style)に沿い、
    日本語で一つだけ自然な追い質問を返します。出力は質問文のみ。
    angle: Depth/Breadth/Contrast/Timeline のいずれか。
    style: A/B/C。Aは共感を一言添えてから質問、Bは要点を短く言い換えてから対比/深掘りの質問、Cは理論的な一言の後に問い。
  SYS

  def initialize(client: Llm::OpenaiClient.new)
    @client = client
  end

  # 返り値: [{ "type"=>"belief|like|strength", "text"=>"..."}, ...] or nil
  def extract_focus_points(user_reply)
    messages = [
      { role: "system", content: SYSTEM_EXTRACT },
      { role: "user",   content: user_reply.to_s }
    ]
    res = @client.chat(messages, temperature: 0.1, response_format: :json)
    res&.dig(:tool_json).is_a?(Array) ? res[:tool_json].first(4) : nil
  end

  # 返り値: String or nil
  def generate_reply(user_reply:, extracted:, angle:, style:)
    prefix =
      case style
      when "A" then "（共感をひとこと添えてから）"
      when "B" then "（要点をひとことで示してから）"
      when "C" then "（理論的な一言を添えてから）"
      else ""
      end

    context = <<~CTX
      ユーザ発話: #{user_reply}
      抽出結果(JSON): #{extracted.to_json}
      指定 angle: #{angle}
      指定 style: #{style}
    CTX

    messages = [
      { role: "system", content: SYSTEM_REPLY },
      { role: "user",   content: "#{prefix}\n#{context}\n質問文のみを出力してください。" }
    ]
    res = @client.chat(messages, temperature: 0.5, response_format: :text)
    res&.dig(:text)
  end
end
