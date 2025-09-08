# frozen_string_literal: true
# app/services/llm/openai_client.rb
# ------------------------------------------------------------
# OpenAI API の薄いラッパ。Net::HTTP で依存最小にし、外部Gemに寄らない。
# - Chat Completions エンドポイントを利用（安定・互換性重視）
# - タイムアウト/429/5xx を吸収しやすいインターフェイス
# - 返り値は {text:, tool_json:} の単純ハッシュ
# ------------------------------------------------------------

require 'net/http'
require 'uri'
require 'json'

module Llm
  class OpenaiClient
    DEFAULT_BASE_URL = ENV.fetch('OPENAI_BASE_URL', 'https://api.openai.com')
    CHAT_PATH        = ENV.fetch('OPENAI_CHAT_PATH', '/v1/chat/completions')
    MODEL_DEFAULT    = ENV.fetch('OPENAI_MODEL', 'gpt-4o-mini') # 運用に合わせて変更可

    def initialize(api_key: nil, model: MODEL_DEFAULT, timeout: 20)
      @api_key = api_key || ENV['OPENAI_API_KEY'] || credentials_api_key
      raise 'OPENAI_API_KEY is not set' if @api_key.to_s.strip.empty?

      @model   = model
      @timeout = timeout
    end

    # messages: [{role:, content:}, ...]
    # response_format: :text | :json ・・・ systemプロンプトでJSON指示する想定
    def chat(messages, temperature: 0.2, response_format: :text)
      uri = URI.parse("#{DEFAULT_BASE_URL}#{CHAT_PATH}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = @timeout
      http.open_timeout = @timeout

      payload = {
        model: @model,
        messages: messages,
        temperature: temperature
      }

      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type']  = 'application/json'
      req['Authorization'] = "Bearer #{@api_key}"
      req.body = JSON.dump(payload)

      res = http.request(req)
      unless res.is_a?(Net::HTTPSuccess)
        raise "OpenAI HTTP #{res.code}: #{res.body.to_s[0,300]}"
      end

      body = JSON.parse(res.body) rescue {}
      text = body.dig('choices', 0, 'message', 'content').to_s

      if response_format == :json
        begin
          tool_json = JSON.parse(text)
          return { text: text, tool_json: tool_json }
        rescue JSON::ParserError
          # JSON失敗時は text のまま返す（上位でフォールバック）
        end
      end

      { text: text, tool_json: nil }
    rescue => e
      # 上位でのフォールバックを容易にするため、例外は投げ直さず nil を返す
      Rails.logger.warn("[OpenaiClient] chat error: #{e.class} #{e.message}")
      nil
    end

    private

    def credentials_api_key
      Rails.application.credentials.dig(:openai, :api_key)
    rescue
      nil
    end
  end
end
