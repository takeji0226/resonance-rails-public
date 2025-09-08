# db/migrate/20250908090000_drop_few_shots.rb
# Purpose: 未使用の few_shots テーブルと関連する enum 型を安全に削除する
# Why: セキュリティ警告の温床（不要な Strong Parameters 等）とスキーマ肥大化を防ぐ
# Note: 本番データは完全に失われます。必要なら事前にバックアップを取得してください。

class DropFewShots < ActiveRecord::Migration[7.2]
  def up
    # 1) 外部キーを先に落とす（存在しない場合はスキップ）
    if foreign_key_exists?(:few_shots, :user_agent_versions)
      remove_foreign_key :few_shots, :user_agent_versions
    end

    # 2) テーブルを削除（存在しないなら何もしない）
    drop_table :few_shots, if_exists: true

    # 3) Postgres の enum 型を削除（この型を使っているカラムが他にない前提）
    execute <<~SQL
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'few_shot_role') THEN
          DROP TYPE few_shot_role;
        END IF;
      END
      $$;
    SQL
  end

  def down
    # Rollback 用: enum → テーブルの順で元に戻す
    # enum 作成（既にあればスキップ）
    execute <<~SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'few_shot_role') THEN
          CREATE TYPE few_shot_role AS ENUM ('user', 'assistant');
        END IF;
      END
      $$;
    SQL

    create_table :few_shots do |t|
      t.references :user_agent_version, null: false, foreign_key: false
      # Rails 7.1+ PG adapter: enum 型の再作成
      t.enum :role, enum_type: "few_shot_role", null: false
      t.text :content, null: false
      t.string :tag
      t.integer :rank, null: false, default: 0
      t.timestamps
    end

    add_index :few_shots, [ :user_agent_version_id, :role, :rank ],
              unique: true, name: "idx_fewshots_uav_role_rank"
    add_index :few_shots, :user_agent_version_id

    add_foreign_key :few_shots, :user_agent_versions
  end
end
