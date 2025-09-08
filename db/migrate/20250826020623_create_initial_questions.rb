class CreateInitialQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :initial_questions do |t|
      t.text :body
      t.string :tag
      t.boolean :active
      t.integer :weight

      t.timestamps
    end
  end
end
