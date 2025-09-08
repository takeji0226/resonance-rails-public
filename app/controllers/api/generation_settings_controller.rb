# app/controllers/api/generation_settings_controller.rb
class Api::GenerationSettingsController < ApplicationController
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :null_session

  def create
    gs = GenerationSetting.new(gs_params)
    if gs.save
      render json: gs, status: :created
    else
      render json: { errors: gs.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    gs = GenerationSetting.find(params[:id])
    if gs.update(gs_params)
      render json: gs
    else
      render json: { errors: gs.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def gs_params
    common = [
      :user_agent_version_id, :model, :temperature, :top_p, :max_output_tokens,
      :seed, :presence_penalty, :frequency_penalty, :response_format,
      :json_schema_name, :preferred_tool_name, :reasoning_effort,
      :use_stream, :allow_prompt_caching, :cache_tag, :label
    ]

    nested = params.fetch(:generation_setting, {}).permit(*common,
      metadata: {}, logit_bias: {}
    )
    flat = params.permit(*common,
      metadata: {}, logit_bias: {}
    )

    nested.merge(flat)  # 競合時はフラット優先
  end
end
