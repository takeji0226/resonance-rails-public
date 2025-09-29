# frozen_string_literal: true
# Conversation: ユーザの会話スレッド。MVPでは1ユーザ=アクティブ1本。
class Conversation < ApplicationRecord
  belongs_to :user
  has_many :chat_messages, dependent: :destroy

  scope :active_for, ->(user) { where(user:, archived: false) }
end
