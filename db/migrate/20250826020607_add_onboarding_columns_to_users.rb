class AddOnboardingColumnsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :onboarding_stage, :string
    add_column :users, :first_login_at, :datetime
  end
end
