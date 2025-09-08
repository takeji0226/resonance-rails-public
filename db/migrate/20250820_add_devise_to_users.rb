# db/migrate/20250820_add_devise_to_users.rb
class AddDeviseToUsers < ActiveRecord::Migration[7.2]
  def up
    change_table :users, bulk: true do |t|
      t.string   :encrypted_password, null: false, default: ""
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string   :jti, null: false, default: ""
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true

    say_with_time "Backfilling JTI for existing users" do
      require "securerandom"
      # モデルを直接使うときは validations を避けるため update_columns を使う
      User.reset_column_information
      User.where(jti: [ nil, "" ]).find_each(batch_size: 1000) do |u|
        u.update_columns(jti: SecureRandom.uuid)
      end
    end

    add_index :users, :jti, unique: true
  end

  def down
    remove_index :users, :jti rescue nil
    remove_index :users, :reset_password_token rescue nil
    remove_index :users, :email rescue nil

    change_table :users, bulk: true do |t|
      t.remove :jti, :remember_created_at, :reset_password_sent_at,
               :reset_password_token, :encrypted_password
    end
  end
end
