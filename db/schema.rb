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

ActiveRecord::Schema[8.0].define(version: 2025_08_23_161747) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bonus_buy_rewards", force: :cascade do |t|
    t.integer "bonus_id", null: false
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
    t.integer "bonus_id", null: false
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
    t.integer "bonus_id", null: false
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
    t.text "currencies"
    t.text "groups"
    t.text "no_more"
    t.integer "totally_no_more"
    t.text "currency_minimum_deposits"
    t.text "description"
    t.string "maximum_winnings_type", default: "multiplier", null: false
    t.index ["availability_end_date"], name: "index_bonuses_on_availability_end_date"
    t.index ["availability_start_date"], name: "index_bonuses_on_availability_start_date"
    t.index ["code"], name: "index_bonuses_on_code"
    t.index ["country"], name: "index_bonuses_on_country"
    t.index ["dsl_tag"], name: "index_bonuses_on_dsl_tag"
    t.index ["event"], name: "index_bonuses_on_event"
    t.index ["project"], name: "index_bonuses_on_project"
    t.index ["status"], name: "index_bonuses_on_status"
    t.index ["user_group"], name: "index_bonuses_on_user_group"
  end

  create_table "collect_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.string "collection_type", null: false
    t.decimal "collection_amount", precision: 15, scale: 2
    t.string "collection_frequency", default: "daily"
    t.integer "collection_limit", default: 1
    t.integer "collected_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_collect_bonuses_on_bonus_id"
    t.index ["collection_frequency"], name: "index_collect_bonuses_on_collection_frequency"
    t.index ["collection_type"], name: "index_collect_bonuses_on_collection_type"
  end

  create_table "comp_point_rewards", force: :cascade do |t|
    t.integer "bonus_id", null: false
    t.integer "points_amount", null: false
    t.decimal "multiplier", precision: 5, scale: 2
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["bonus_id"], name: "index_comp_point_rewards_on_bonus_id"
    t.index ["points_amount"], name: "index_comp_point_rewards_on_points_amount"
  end

  create_table "deposit_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.decimal "deposit_amount_required", precision: 10, scale: 2
    t.decimal "bonus_percentage", precision: 5, scale: 2
    t.decimal "max_bonus_amount", precision: 15, scale: 2
    t.boolean "first_deposit_only", default: false
    t.boolean "recurring_eligible", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_deposit_bonuses_on_bonus_id"
  end

  create_table "freechip_rewards", force: :cascade do |t|
    t.integer "bonus_id", null: false
    t.decimal "chip_value", precision: 15, scale: 2, null: false
    t.integer "chips_count", null: false
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_freechip_rewards_on_bonus_id"
    t.index ["chip_value"], name: "index_freechip_rewards_on_chip_value"
  end

  create_table "freespin_rewards", force: :cascade do |t|
    t.integer "bonus_id", null: false
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

  create_table "groups_update_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.text "target_groups", null: false
    t.string "update_type", null: false
    t.text "update_parameters"
    t.integer "batch_size", default: 100
    t.string "processing_status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_groups_update_bonuses_on_bonus_id"
    t.index ["processing_status"], name: "index_groups_update_bonuses_on_processing_status"
    t.index ["update_type"], name: "index_groups_update_bonuses_on_update_type"
  end

  create_table "input_coupon_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.string "coupon_code", null: false
    t.integer "usage_limit", default: 1
    t.integer "usage_count", default: 0
    t.datetime "expires_at"
    t.boolean "single_use", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_input_coupon_bonuses_on_bonus_id"
    t.index ["coupon_code"], name: "index_input_coupon_bonuses_on_coupon_code", unique: true
    t.index ["expires_at"], name: "index_input_coupon_bonuses_on_expires_at"
  end

  create_table "manual_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.text "admin_notes"
    t.boolean "approval_required", default: true
    t.boolean "auto_apply", default: false
    t.text "conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approval_required"], name: "index_manual_bonuses_on_approval_required"
    t.index ["auto_apply"], name: "index_manual_bonuses_on_auto_apply"
    t.index ["bonus_id"], name: "index_manual_bonuses_on_bonus_id"
  end

  create_table "marketing_requests", force: :cascade do |t|
    t.string "manager", null: false
    t.text "platform"
    t.string "partner_email", null: false
    t.text "promo_code"
    t.string "stag", null: false
    t.datetime "activation_date"
    t.string "status", default: "pending", null: false
    t.string "request_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_email"], name: "index_marketing_requests_on_partner_email"
    t.index ["promo_code"], name: "index_marketing_requests_on_promo_code", unique: true
    t.index ["request_type"], name: "index_marketing_requests_on_request_type"
    t.index ["stag"], name: "index_marketing_requests_on_stag", unique: true
    t.index ["status"], name: "index_marketing_requests_on_status"
  end

  create_table "material_prize_rewards", force: :cascade do |t|
    t.integer "bonus_id", null: false
    t.string "prize_name", null: false
    t.decimal "prize_value", precision: 15, scale: 2
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_material_prize_rewards_on_bonus_id"
    t.index ["prize_name"], name: "index_material_prize_rewards_on_prize_name"
  end

  create_table "scheduler_bonuses", force: :cascade do |t|
    t.bigint "bonus_id", null: false
    t.string "schedule_type", null: false
    t.string "cron_expression"
    t.datetime "next_run_at"
    t.datetime "last_run_at"
    t.integer "execution_count", default: 0
    t.integer "max_executions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_scheduler_bonuses_on_bonus_id"
    t.index ["last_run_at"], name: "index_scheduler_bonuses_on_last_run_at"
    t.index ["next_run_at"], name: "index_scheduler_bonuses_on_next_run_at"
    t.index ["schedule_type"], name: "index_scheduler_bonuses_on_schedule_type"
  end

  add_foreign_key "bonus_buy_rewards", "bonuses"
  add_foreign_key "bonus_code_rewards", "bonuses"
  add_foreign_key "bonus_rewards", "bonuses"
  add_foreign_key "comp_point_rewards", "bonuses"
  add_foreign_key "freechip_rewards", "bonuses"
  add_foreign_key "freespin_rewards", "bonuses"
  add_foreign_key "material_prize_rewards", "bonuses"
end
