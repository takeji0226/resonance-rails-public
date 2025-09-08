# db/migrate/20250817000300_create_generation_settings.rb
class CreateGenerationSettings < ActiveRecord::Migration[7.2]
  def change
    create_enum :response_format, %w[text json json_schema]
    create_enum :tool_choice, %w[auto required none]
    create_enum :reasoning_effort, %w[low medium high]

    create_table :generation_settings do |t|
      t.references :user_agent_version, null: false, foreign_key: true, index: { unique: true }
      t.string  :model, null: false
      t.decimal :temperature, precision: 3, scale: 2, default: 0.6
      t.decimal :top_p, precision: 3, scale: 2, default: 1.0
      t.integer :max_output_tokens
      t.integer :seed
      t.decimal :presence_penalty, precision: 3, scale: 2, default: 0
      t.decimal :frequency_penalty, precision: 3, scale: 2, default: 0
      t.jsonb   :logit_bias, default: {}
      t.enum    :response_format, enum_type: :response_format, default: "text", null: false
      t.string  :json_schema_name
      t.enum    :tool_choice, enum_type: :tool_choice, default: "auto", null: false
      t.string  :preferred_tool_name
      t.enum    :reasoning_effort, enum_type: :reasoning_effort
      t.boolean :use_stream, default: true, null: false
      t.boolean :allow_prompt_caching, default: true, null: false
      t.string  :cache_tag
      t.string  :label
      t.jsonb   :metadata, default: {}
      t.timestamps
    end

    # CHECK制約
    execute <<~SQL
      ALTER TABLE generation_settings
        ADD CONSTRAINT chk_temperature_range CHECK (temperature BETWEEN 0 AND 2),
        ADD CONSTRAINT chk_top_p_range CHECK (top_p BETWEEN 0 AND 1),
        ADD CONSTRAINT chk_presence_penalty CHECK (presence_penalty BETWEEN -2 AND 2),
        ADD CONSTRAINT chk_frequency_penalty CHECK (frequency_penalty BETWEEN -2 AND 2),
        ADD CONSTRAINT chk_json_schema_name_required
          CHECK (NOT (response_format = 'json_schema' AND json_schema_name IS NULL)),
        ADD CONSTRAINT chk_tool_choice_required_name
          CHECK (NOT (tool_choice = 'required' AND preferred_tool_name IS NULL));
    SQL
  end
end
