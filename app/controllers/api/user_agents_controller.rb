# app/controllers/api/user_agents_controller.rb
class Api::UserAgentsController < ApplicationController
  #protect_from_forgery with: :null_session
  skip_forgery_protection

  def show
    render json: UserAgent.find_by!(user_id: params[:id])
  end

  def create
    ua = UserAgent.create!(user_id: params[:user_id], name: params[:name], description: params[:description], is_active: params.fetch(:is_active, true))
    render json: ua, status: :created
  end

  def update
    ua = UserAgent.find(params[:id])
    ua.update!(params.permit(:name, :description, :is_active))
    render json: ua
  end
end
