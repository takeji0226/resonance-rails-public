# db/migrate/20250817000200_create_user_agent_versions.rb
class CreateUserAgentVersions < ActiveRecord::Migration[7.2]
  def change
    create_enum :user_agent_version_status, %w[draft active archived]

    create_table :user_agent_versions do |t|
      t.references :user_agent, null: false, foreign_key: true
      t.string :version, null: false
      t.text :instructions, null: false
      t.enum :status, enum_type: :user_agent_version_status, null: false, default: "draft"
      t.text :notes
      t.timestamps
    end

    add_index :user_agent_versions, [:user_agent_id, :version], unique: true
  end
end
