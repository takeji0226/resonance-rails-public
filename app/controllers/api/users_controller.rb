# app/controllers/api/users_controller.rb
class Api::UsersController < ApplicationController
before_action :authenticate_user!, only: [ :me ]  # 追加
  # 追加: ログイン中ユーザ
  def me
    u = current_user
    render json: { id: u.id, name: u.name, email: u.email }
  end

  def index
    users = User.select(:id, :name, :email, :created_at, :updated_at)
    render json: users
  end

  def show
    user = User.select(:id, :name, :email, :created_at, :updated_at).find(params[:id])
    render json: user
  end
end
