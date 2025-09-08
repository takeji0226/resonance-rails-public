# app/models/generation_setting.rb
class GenerationSetting < ApplicationRecord
  self.table_name = "generation_settings"
  belongs_to :user_agent_version
  enum :response_format, { text: "text", json: "json", json_schema: "json_schema" }
  enum :reasoning_effort, { low: "low", medium: "medium", high: "high" }
  validates :model, presence: true
end
