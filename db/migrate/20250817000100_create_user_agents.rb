# db/migrate/20250817000100_create_user_agents.rb
class CreateUserAgents < ActiveRecord::Migration[7.2]
  def change
    create_table :user_agents do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
  end
end
