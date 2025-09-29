# frozen_string_literal: true
# == Migration: enforce single active conversation per user
class AddUniqueActiveConversationIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :conversations, :user_id,
      unique: true,
      where: "archived = false",
      name: "idx_unique_active_conversation_per_user"
  end
end
