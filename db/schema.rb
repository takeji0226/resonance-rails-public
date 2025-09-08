# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_08_26_020800) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "few_shot_role", ["user", "assistant"]
  create_enum "reasoning_effort", ["low", "medium", "high"]
  create_enum "response_format", ["text", "json", "json_schema"]
  create_enum "style_guide_status", ["draft", "active", "archived"]
  create_enum "tool_choice", ["auto", "required", "none"]
  create_enum "user_agent_version_status", ["draft", "active", "archived"]

  create_table "few_shots", force: :cascade do |t|
    t.bigint "user_agent_version_id", null: false
    t.enum "role", null: false, enum_type: "few_shot_role"
    t.text "content", null: false
    t.string "tag"
    t.integer "rank", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_agent_version_id", "role", "rank"], name: "idx_fewshots_uav_role_rank", unique: true
    t.index ["user_agent_version_id"], name: "index_few_shots_on_user_agent_version_id"
  end

  create_table "generation_settings", force: :cascade do |t|
    t.bigint "user_agent_version_id", null: false
    t.string "model", null: false
    t.decimal "temperature", precision: 3, scale: 2, default: "0.6"
    t.decimal "top_p", precision: 3, scale: 2, default: "1.0"
    t.integer "max_output_tokens"
    t.integer "seed"
    t.decimal "presence_penalty", precision: 3, scale: 2, default: "0.0"
    t.decimal "frequency_penalty", precision: 3, scale: 2, default: "0.0"
    t.jsonb "logit_bias", default: {}
    t.enum "response_format", default: "text", null: false, enum_type: "response_format"
    t.string "json_schema_name"
    t.string "preferred_tool_name"
    t.enum "reasoning_effort", enum_type: "reasoning_effort"
    t.boolean "use_stream", default: true, null: false
    t.boolean "allow_prompt_caching", default: true, null: false
    t.string "cache_tag"
    t.string "label"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_agent_version_id"], name: "index_generation_settings_on_user_agent_version_id", unique: true
    t.check_constraint "NOT (response_format = 'json_schema'::response_format AND json_schema_name IS NULL)", name: "chk_json_schema_name_required"
    t.check_constraint "frequency_penalty >= '-2'::integer::numeric AND frequency_penalty <= 2::numeric", name: "chk_frequency_penalty"
    t.check_constraint "presence_penalty >= '-2'::integer::numeric AND presence_penalty <= 2::numeric", name: "chk_presence_penalty"
    t.check_constraint "temperature >= 0::numeric AND temperature <= 2::numeric", name: "chk_temperature_range"
    t.check_constraint "top_p >= 0::numeric AND top_p <= 1::numeric", name: "chk_top_p_range"
  end

  create_table "initial_questions", force: :cascade do |t|
    t.text "body"
    t.string "tag"
    t.boolean "active"
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "onboarding_exchanges", force: :cascade do |t|
    t.bigint "onboarding_session_id", null: false
    t.bigint "initial_question_id", null: false
    t.text "user_reply"
    t.jsonb "focus_points"
    t.string "angle"
    t.string "reply_style"
    t.text "assistant_reply"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["initial_question_id"], name: "index_onboarding_exchanges_on_initial_question_id"
    t.index ["onboarding_session_id"], name: "index_onboarding_exchanges_on_onboarding_session_id"
  end

  create_table "onboarding_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stage"
    t.integer "cycles_target"
    t.integer "cycles_done"
    t.jsonb "summary_beliefs"
    t.jsonb "summary_likes"
    t.jsonb "summary_strengths"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_onboarding_sessions_on_user_id"
  end

  create_table "style_guides", force: :cascade do |t|
    t.bigint "user_agent_version_id", null: false
    t.string "label"
    t.enum "status", default: "draft", null: false, enum_type: "style_guide_status"
    t.jsonb "rules", default: {}
    t.jsonb "rubric", default: {}
    t.jsonb "lint_rules", default: {}
    t.jsonb "applies_to", default: {}
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_agent_version_id"], name: "index_style_guides_on_user_agent_version_id", unique: true
  end

  create_table "user_agent_versions", force: :cascade do |t|
    t.bigint "user_agent_id", null: false
    t.string "version", null: false
    t.text "instructions", null: false
    t.enum "status", default: "draft", null: false, enum_type: "user_agent_version_status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_agent_id", "version"], name: "index_user_agent_versions_on_user_agent_id_and_version", unique: true
    t.index ["user_agent_id"], name: "index_user_agent_versions_on_user_agent_id"
  end

  create_table "user_agents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_agents_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "jti", default: "", null: false
    t.string "onboarding_stage"
    t.datetime "first_login_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "few_shots", "user_agent_versions"
  add_foreign_key "generation_settings", "user_agent_versions"
  add_foreign_key "onboarding_exchanges", "initial_questions"
  add_foreign_key "onboarding_exchanges", "onboarding_sessions"
  add_foreign_key "onboarding_sessions", "users"
  add_foreign_key "style_guides", "user_agent_versions"
  add_foreign_key "user_agent_versions", "user_agents"
  add_foreign_key "user_agents", "users"
end
