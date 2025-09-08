# app/controllers/api/pings_controller.rb
class Api::PingsController < ApplicationController
  include ActionController::Live

  def stream
    response.headers["Content-Type"] = "text/event-stream; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    3.times do |i|
      response.stream.write "data: #{ {tick: i+1, msg: "hello"}.to_json }\n\n"
      sleep 0.2
    end
  ensure
    response.stream.close
  end
end
