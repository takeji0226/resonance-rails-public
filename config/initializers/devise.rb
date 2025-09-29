# frozen_string_literal: true

# Assuming you have not yet modified this file, each configuration option below
# is set to its default value. Note that some are commented out while others
# are not: uncommented lines are intended to protect your configuration from
# breaking changes in upgrades (i.e., in the event that future versions of
# Devise change the default values for those options).
#
# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
# ★ API ではHTMLナビゲーション挙動(=フラッシュ等)を無効化
config.navigational_formats = []

config.jwt do |jwt|
  jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY") # .env 等で設定
  jwt.dispatch_requests = [
    [ "POST", %r{^/users/sign_in$} ]
  ]
  jwt.revocation_requests = [
    [ "DELETE", %r{^/users/sign_out$} ]
  ]
  jwt.expiration_time = 1.day.to_i
  jwt.request_formats = { user: [ :json ] }
end

  config.mailer_sender = "please-change-me-at-config-initializers-devise@example.com"

  require "devise/orm/active_record"

  config.case_insensitive_keys = [ :email ]

  config.strip_whitespace_keys = [ :email ]

  # ★ APIではセッション保存の機会を減らす（任意）
  config.skip_session_storage = [ :http_auth, :params_auth ]
  # ★ APIならナビゲーショナル(HTML)振る舞いを止めると安定
  config.navigational_formats = []

  config.stretches = Rails.env.test? ? 1 : 12

  config.reconfirmable = true

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 6..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

end
