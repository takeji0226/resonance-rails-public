# frozen_string_literal: true
# 現在ログイン中のユーザー情報を返す軽量エンドポイント
# - 理由: フロント初期表示時に「選択ユーザー」を current_user で自動セットするため
# - 注意: 必ず認証後のみ到達するように before_action をかけること
module Api
  module V1
    class MeController < ApplicationController
      before_action :authenticate_user!  # Devise想定。別方式なら等価の認証フィルタに置換。

      def show
        render json: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email
        }
      end
    end
  end
end
