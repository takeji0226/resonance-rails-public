# db/migrate/XXXXXXXXXXXX_drop_onboarding_tables.rb
# -----------------------------------------------------------------------------
# 目的:
# - onboading関連の3テーブルを削除する（依存関係を考慮し、子→親の順にdrop）
# - downで元のスキーマに復元できるように再定義する
#
# 注意:
# - Postgresの外部キー制約があるため、dropの順序は
#   onboarding_exchanges → onboarding_sessions / initial_questions の順
# - 既に手動で消えていても落ちないように if_exists: true を付与
# - 復元順は親→子の順（initial_questions → onboarding_sessions → onboarding_exchanges）
#
class DropOnboardingTables < ActiveRecord::Migration[7.2]
  def up
    # 子テーブル（外部キーがぶら下がっている）を先に落とす
    drop_table :onboarding_exchanges, if_exists: true

    # 親テーブルを落とす
    drop_table :onboarding_sessions, if_exists: true
    drop_table :initial_questions, if_exists: true
  end

  def down
    # 復元: 先に親テーブルから作る

    # initial_questions
    create_table :initial_questions do |t|
      t.text :body
      t.string :tag
      t.boolean :active
      t.integer :weight
      t.timestamps
    end

    # onboarding_sessions
    create_table :onboarding_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stage
      t.integer :cycles_target
      t.integer :cycles_done
      t.jsonb :summary_beliefs
      t.jsonb :summary_likes
      t.jsonb :summary_strengths
      t.timestamps
    end

    # onboarding_exchanges（子: 外部キーで initial_questions / onboarding_sessions を参照）
    create_table :onboarding_exchanges do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.references :initial_question, null: false, foreign_key: true
      t.text :user_reply
      t.jsonb :focus_points
      t.string :angle
      t.string :reply_style
      t.text :assistant_reply
      t.timestamps
    end
  end
end
