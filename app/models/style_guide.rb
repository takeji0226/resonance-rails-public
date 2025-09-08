# app/models/style_guide.rb
class StyleGuide < ApplicationRecord
  belongs_to :user_agent_version
  enum :status, { draft: "draft", active: "active", archived: "archived" }
end
