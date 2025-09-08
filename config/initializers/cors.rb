# config/initializers/cors.rb
# Purpose: CORS 設定（ENV を正規化し nil/空を除去）
# Why: rack-cors が origins に nil を渡すと Regexp.quote(nil) で TypeError になるため
# Notes:
#   - CORS_ALLOWED_ORIGINS はカンマ区切り対応（例: "https://a.com,https://b.com"）
#   - production では許可オリジン未設定をエラーにして事故防止
#   - dev/test はローカル既定値にフォールバックし、CI でも安定動作

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 候補を収集（環境変数のいずれかに設定があれば拾う）
    raw_origins = [
      ENV["CORS_ALLOWED_ORIGINS"], # 例: "https://a.com,https://b.com"
      ENV["FRONTEND_ORIGIN"],      # 例: "https://app.example.com"
      ENV["NEXT_PUBLIC_APP_ORIGIN"]
    ].compact

    # カンマ/空白で分割 → 前後空白トリム → 空要素除去
    normalized = raw_origins.flat_map { |s| s.to_s.split(/[,\s]+/) }
                            .map(&:strip)
                            .reject(&:blank?)

    allowed_origins =
      if Rails.env.production?
        raise "CORS origins are not configured. Set CORS_ALLOWED_ORIGINS or FRONTEND_ORIGIN." if normalized.empty?
        normalized
      else
        # dev/test の既定値（ENV があればそちら優先）
        normalized.presence || %w[http://localhost:3000 http://127.0.0.1:3000]
      end

    origins(*allowed_origins)

    # API 系
    resource "/api/*",
             headers: :any,
             expose: [ "Authorization" ],
             methods: %i[get post put patch delete options head],
             credentials: true

    # 認証系
    resource "/users/*",
             headers: :any,
             expose: [ "Authorization" ],
             methods: %i[get post put patch delete options head],
             credentials: true

    # ヘルスチェック
    resource "/health",
             headers: :any,
             methods: %i[get options head],
             credentials: true
  end
end
