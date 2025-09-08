# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors


# 20250814 next.js connect test
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV["FRONTEND_ORIGIN"] # 本番は正確なオリジンに絞る

    # DBリソース、外部APIアクセス系許可
    resource "/api/*",
      headers: :any,
      expose: [ "Authorization" ],
      methods: %i[get post put patch delete options head],
      credentials: true
    # 認証系許可
    resource "/users/*",
      headers: :any,
      expose: [ "Authorization" ],
      methods: %i[get post put patch delete options head],
      credentials: true

    resource "/health",
      headers: :any,
      methods: %i[get options head],
      credentials: true
    end
end
