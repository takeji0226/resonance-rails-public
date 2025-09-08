# db/migrate/20250817000500_create_few_shots.rb
class CreateFewShots < ActiveRecord::Migration[7.2]
  def up
    # Postgres ENUM（ロールを厳密管理）
    create_enum :few_shot_role, %w[user assistant]

    create_table :few_shots do |t|
      t.references :user_agent_version, null: false, foreign_key: true
      t.enum    :role, enum_type: :few_shot_role, null: false
      t.text    :content, null: false
      t.string  :tag
      t.integer :rank, default: 0, null: false
      t.timestamps
    end

    add_index :few_shots,
              [ :user_agent_version_id, :role, :rank ],
              unique: true,
              name: "idx_fewshots_uav_role_rank"
  end

  def down
    remove_index :few_shots, name: "idx_fewshots_uav_role_rank", if_exists: true
    drop_table :few_shots, if_exists: true
    # ENUMは明示的に削除（ロールバック時のゴミ残り防止）
    drop_enum :few_shot_role, if_exists: true
  end
end
