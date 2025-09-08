# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  respond_to :json

  # ★ APIならCSRFを無効化（これで「Can't verify CSRF token authenticity.」を回避）
  skip_forgery_protection

  # 明示的に public な destroy を作って Rails 7.1 の厳格チェックを満たす
  def destroy
    super
  end

  private

  # 初回ユーザ確認の上、初回ユーザに対してオンボード画面を表示
  def respond_with(resource, _opts = {})
    if resource.first_login_at.nil?
      resource.update!(first_login_at: Time.current, onboarding_stage: "philosophy")
    end
    render json: { message: "signed_in", user: { id: resource.id, email: resource.email } }, status: :ok
  end
  def respond_to_on_destroy
    render json: { message: "signed_out" }, status: :ok
  end
end
