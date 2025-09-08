# app/controllers/api/onboarding_controller.rb
class Api::OnboardingController < ApplicationController
  before_action :authenticate_user!

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


end
