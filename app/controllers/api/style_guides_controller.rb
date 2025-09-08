# app/controllers/api/style_guides_controller.rb
class Api::StyleGuidesController < ApplicationController
  protect_from_forgery with: :null_session
  def create
    sg = StyleGuide.create!(params.permit(:user_agent_version_id, :label, :status, :rules, :rubric, :lint_rules, :applies_to, :notes))
    render json: sg, status: :created
  end

  def update
    sg = StyleGuide.find(params[:id])
    sg.update!(params.permit(:label, :status, :rules, :rubric, :lint_rules, :applies_to, :notes))
    render json: sg
  end
end
