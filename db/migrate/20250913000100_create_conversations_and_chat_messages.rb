# frozen_string_literal: true
# == Migration: create conversations & chat_messages
# 目的: 1ユーザ=1アクティブ会話（archived=false）にメッセージを積む最小構成
class CreateConversationsAndChatMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :title
      t.boolean :archived, null: false, default: false
      t.timestamps
    end
    add_index :conversations, [:user_id, :archived]

    create_table :chat_messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string  :role,    null: false # 'user' | 'assistant' | 'system'
      t.text    :content, null: false
      t.jsonb   :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :chat_messages, [:conversation_id, :created_at]
  end
end
