class CreateOnboardingSessions < ActiveRecord::Migration[7.2]
  def change
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
  end
end
