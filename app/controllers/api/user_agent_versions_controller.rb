# app/controllers/api/user_agent_versions_controller.rb
class Api::UserAgentVersionsController < ApplicationController
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :null_session

  def create
    uav = UserAgentVersion.new(uav_params)
    if uav.save
      render json: uav, status: :created
    else
      render json: { errors: uav.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  def uav_params
    # リクエストが { user_agent_version: { ... } } ならその中をpermit
    # フラット({ user_agent_id: ..., version: ... })ならトップをpermit
    src = params[:user_agent_version].present? ? params.require(:user_agent_version) : params
    src.permit(:user_agent_id, :version, :instructions, :status, :notes)
  end
end
