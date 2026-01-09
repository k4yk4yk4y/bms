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

ActiveRecord::Schema[8.0].define(version: 2026_01_09_150121) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "bonus_audit_logs", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.bigint "user_id", null: false
    t.string "action"
    t.text "changes_data"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_bonus_audit_logs_on_bonus_id"
    t.index ["user_id"], name: "index_bonus_audit_logs_on_user_id"
  end

  create_table "bonus_buy_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.decimal "buy_amount", precision: 15, scale: 2
    t.decimal "multiplier", precision: 5, scale: 2
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "games", default: "--- []\n"
    t.float "bet_level"
    t.string "code"
    t.string "stag"
    t.decimal "max_win_value", precision: 15, scale: 2
    t.string "max_win_type", default: "fixed"
    t.integer "available"
    t.index ["bonus_id"], name: "index_bonus_buy_rewards_on_bonus_id"
    t.index ["buy_amount"], name: "index_bonus_buy_rewards_on_buy_amount"
  end

  create_table "bonus_code_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.string "code", null: false
    t.string "code_type", null: false
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["bonus_id"], name: "index_bonus_code_rewards_on_bonus_id"
    t.index ["code"], name: "index_bonus_code_rewards_on_code", unique: true
    t.index ["code_type"], name: "index_bonus_code_rewards_on_code_type"
  end

  create_table "bonus_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.string "reward_type", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.decimal "percentage", precision: 5, scale: 2
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.boolean "user_can_have_duplicates", default: false
    t.string "stag"
    t.text "currency_amounts"
    t.decimal "max_win_value", precision: 15, scale: 2
    t.string "max_win_type", default: "fixed"
    t.integer "available"
    t.index ["bonus_id", "reward_type"], name: "index_bonus_rewards_on_bonus_id_and_reward_type"
    t.index ["bonus_id"], name: "index_bonus_rewards_on_bonus_id"
    t.index ["reward_type"], name: "index_bonus_rewards_on_reward_type"
  end

  create_table "bonus_templates", force: :cascade do |t|
    t.string "name"
    t.string "dsl_tag"
    t.string "project"
    t.string "event"
    t.decimal "minimum_deposit"
    t.decimal "wager"
    t.decimal "maximum_winnings"
    t.integer "no_more"
    t.integer "totally_no_more"
    t.text "currencies"
    t.text "groups"
    t.text "currency_minimum_deposits"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dsl_tag", "project", "name"], name: "index_bonus_templates_on_dsl_tag_project_name", unique: true
    t.index ["dsl_tag"], name: "index_bonus_templates_on_dsl_tag"
    t.index ["project"], name: "index_bonus_templates_on_project"
  end

  create_table "bonuses", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "status", default: "active"
    t.decimal "minimum_deposit", precision: 10, scale: 2
    t.decimal "wager", precision: 10, scale: 2
    t.decimal "maximum_winnings", precision: 15, scale: 2
    t.string "wagering_strategy"
    t.datetime "availability_start_date", null: false
    t.datetime "availability_end_date", null: false
    t.string "user_group"
    t.text "tags"
    t.string "country"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project"
    t.string "dsl_tag"
    t.string "event", null: false
    t.text "currencies", comment: "JSON array of supported currencies"
    t.text "groups", comment: "JSON array of target user groups"
    t.text "no_more", comment: "Usage limitation string (e.g., \"1 per day\", \"3 per week\")"
    t.integer "totally_no_more", comment: "Total limit of activations across all players"
    t.text "currency_minimum_deposits"
    t.text "description"
    t.string "maximum_winnings_type", default: "multiplier", null: false
    t.bigint "dsl_tag_id"
    t.index ["availability_end_date"], name: "index_bonuses_on_availability_end_date"
    t.index ["availability_start_date"], name: "index_bonuses_on_availability_start_date"
    t.index ["code"], name: "index_bonuses_on_code"
    t.index ["country"], name: "index_bonuses_on_country"
    t.index ["dsl_tag"], name: "index_bonuses_on_dsl_tag"
    t.index ["dsl_tag_id"], name: "index_bonuses_on_dsl_tag_id"
    t.index ["event"], name: "index_bonuses_on_event"
    t.index ["project"], name: "index_bonuses_on_project"
    t.index ["status"], name: "index_bonuses_on_status"
    t.index ["user_group"], name: "index_bonuses_on_user_group"
  end

  create_table "comp_point_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.integer "points_amount", null: false
    t.decimal "multiplier", precision: 5, scale: 2
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["bonus_id"], name: "index_comp_point_rewards_on_bonus_id"
    t.index ["points_amount"], name: "index_comp_point_rewards_on_points_amount"
  end

  create_table "dsl_tags", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dsl_tags_on_name", unique: true
  end

  create_table "freechip_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.decimal "chip_value", precision: 15, scale: 2, null: false
    t.integer "chips_count", null: false
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_freechip_rewards_on_bonus_id"
    t.index ["chip_value"], name: "index_freechip_rewards_on_chip_value"
  end

  create_table "freespin_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.integer "spins_count", null: false
    t.text "game_restrictions"
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "games", default: "--- []\n"
    t.float "bet_level"
    t.string "code"
    t.string "stag"
    t.decimal "max_win_value", precision: 15, scale: 2
    t.string "max_win_type", default: "fixed"
    t.integer "available"
    t.index ["bonus_id"], name: "index_freespin_rewards_on_bonus_id"
    t.index ["spins_count"], name: "index_freespin_rewards_on_spins_count"
  end

  create_table "heatmap_comments", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.text "text"
    t.bigint "user_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_heatmap_comments_on_user_id"
  end

  create_table "marketing_requests", force: :cascade do |t|
    t.string "manager", null: false
    t.text "platform"
    t.string "partner_email", null: false
    t.text "promo_code", null: false
    t.string "stag", null: false
    t.datetime "activation_date"
    t.string "status", default: "pending", null: false
    t.string "request_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manager"], name: "index_marketing_requests_on_manager"
    t.index ["partner_email"], name: "index_marketing_requests_on_partner_email"
    t.index ["promo_code"], name: "index_marketing_requests_on_promo_code"
    t.index ["request_type"], name: "index_marketing_requests_on_request_type"
    t.index ["stag"], name: "index_marketing_requests_on_stag", unique: true
    t.index ["status"], name: "index_marketing_requests_on_status"
  end

  create_table "material_prize_rewards", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.string "prize_name", null: false
    t.decimal "prize_value", precision: 15, scale: 2
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_material_prize_rewards_on_bonus_id"
    t.index ["prize_name"], name: "index_material_prize_rewards_on_prize_name"
  end

  create_table "permanent_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.index ["bonus_id"], name: "index_permanent_bonuses_on_bonus_id"
    t.index ["project_id"], name: "index_permanent_bonuses_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_projects_on_name", unique: true
  end

  create_table "retention_chains", force: :cascade do |t|
    t.string "name"
    t.bigint "project_id"
    t.string "status", default: "draft", null: false
    t.datetime "launch_date"
    t.integer "retention_emails_count", default: 0, null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by"], name: "index_retention_chains_on_created_by"
    t.index ["launch_date"], name: "index_retention_chains_on_launch_date"
    t.index ["project_id"], name: "index_retention_chains_on_project_id"
    t.index ["status"], name: "index_retention_chains_on_status"
  end

  create_table "retention_email_bonuses", force: :cascade do |t|
    t.bigint "retention_email_id", null: false
    t.bigint "bonus_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_retention_email_bonuses_on_bonus_id"
    t.index ["retention_email_id", "bonus_id"], name: "index_retention_email_bonuses_on_email_and_bonus", unique: true
    t.index ["retention_email_id"], name: "index_retention_email_bonuses_on_retention_email_id"
  end

  create_table "retention_emails", force: :cascade do |t|
    t.bigint "retention_chain_id", null: false
    t.string "subject"
    t.string "preheader"
    t.string "header"
    t.text "body"
    t.string "send_timing"
    t.text "description"
    t.string "status", default: "draft", null: false
    t.datetime "launch_date"
    t.integer "position"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["launch_date"], name: "index_retention_emails_on_launch_date"
    t.index ["retention_chain_id", "position"], name: "index_retention_emails_on_retention_chain_id_and_position"
    t.index ["retention_chain_id"], name: "index_retention_emails_on_retention_chain_id"
    t.index ["status"], name: "index_retention_emails_on_status"
  end

  create_table "roles", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "role", default: 3
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bonus_audit_logs", "bonuses"
  add_foreign_key "bonus_audit_logs", "users"
  add_foreign_key "bonus_buy_rewards", "bonuses"
  add_foreign_key "bonus_code_rewards", "bonuses"
  add_foreign_key "bonus_rewards", "bonuses"
  add_foreign_key "bonuses", "dsl_tags"
  add_foreign_key "comp_point_rewards", "bonuses"
  add_foreign_key "freechip_rewards", "bonuses"
  add_foreign_key "freespin_rewards", "bonuses"
  add_foreign_key "heatmap_comments", "users"
  add_foreign_key "material_prize_rewards", "bonuses"
  add_foreign_key "permanent_bonuses", "bonuses"
  add_foreign_key "permanent_bonuses", "projects"
  add_foreign_key "retention_chains", "projects"
  add_foreign_key "retention_email_bonuses", "bonuses"
  add_foreign_key "retention_email_bonuses", "retention_emails"
  add_foreign_key "retention_emails", "retention_chains"
end
