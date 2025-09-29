# frozen_string_literal: true
# ChatMessage: 1発言を保持
class ChatMessage < ApplicationRecord
  belongs_to :conversation

  validates :role, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true
end
