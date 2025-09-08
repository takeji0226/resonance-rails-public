class CreateOnboardingExchanges < ActiveRecord::Migration[7.2]
  def change
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
