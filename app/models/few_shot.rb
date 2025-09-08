# app/models/few_shot.rb
class FewShot < ApplicationRecord
  belongs_to :user_agent_version
  enum :role, { user: "user", assistant: "assistant" }
  validates :content, presence: true
end
