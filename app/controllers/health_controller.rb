class HealthController < ApplicationController
  def index
    render json: { status: "ok", time: Time.current }
  end
end
