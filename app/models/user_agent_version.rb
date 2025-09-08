# app/models/user_agent_version.rb
class UserAgentVersion < ApplicationRecord
  belongs_to :user_agent
  has_one :generation_setting, dependent: :destroy
  has_one :style_guide, dependent: :destroy
  has_many :few_shots, dependent: :destroy

  enum :status, { draft: "draft", active: "active", archived: "archived" }, prefix: true
  validates :version, :instructions, presence: true

  scope :for_user, ->(user_id) { joins(:user_agent).where(user_agents: { user_id: user_id }) }
  scope :latest_active_for_user, ->(user_id) {
    for_user(user_id).status_active.order(updated_at: :desc).limit(1)
  }
end
