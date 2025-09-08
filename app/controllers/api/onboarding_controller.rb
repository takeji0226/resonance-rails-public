# app/controllers/api/onboarding_controller.rb
class Api::OnboardingController < ApplicationController
  before_action :authenticate_user!

  # -----------------------------------------------------
  # GET /api/onboarding/status
  # 現在のオンボーディング進捗を返す。
  # 例: { stage: "pebble"}
  # -----------------------------------------------------
  def status
    render json: {
      stage: current_user.onboarding_stage || "none"
    }
  end
end
