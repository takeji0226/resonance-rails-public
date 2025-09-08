# app/models/user_agent.rb
class UserAgent < ApplicationRecord
  belongs_to :user
  has_many :user_agent_versions, dependent: :destroy
  validates :name, presence: true
end
