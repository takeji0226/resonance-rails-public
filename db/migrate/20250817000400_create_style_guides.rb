# db/migrate/20250817000400_create_style_guides.rb
class CreateStyleGuides < ActiveRecord::Migration[7.2]
  def change
    create_enum :style_guide_status, %w[draft active archived]

    create_table :style_guides do |t|
      t.references :user_agent_version, null: false, foreign_key: true, index: { unique: true }
      t.string  :label
      t.enum    :status, enum_type: :style_guide_status, default: "draft", null: false
      t.jsonb   :rules, default: {}
      t.jsonb   :rubric, default: {}
      t.jsonb   :lint_rules, default: {}
      t.jsonb   :applies_to, default: {}
      t.text    :notes
      t.timestamps
    end
  end
end
