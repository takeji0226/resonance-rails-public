# app/controllers/api/few_shots_controller.rb
class Api::FewShotsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    render json: FewShot.where(user_agent_version_id: params[:user_agent_version_id]).order(:role, :rank)
  end

  def create
    fs = FewShot.create!(params.permit(:user_agent_version_id, :role, :content, :tag, :rank))
    render json: fs, status: :created
  end

  def destroy
    FewShot.find(params[:id]).destroy!
    head :no_content
  end
end
