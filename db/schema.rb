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

ActiveRecord::Schema[8.0].define(version: 2025_08_12_193953) do
  create_table "bonuses", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "bonus_type", null: false
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
    t.string "currency", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project"
    t.string "dsl_tag"
    t.index ["availability_end_date"], name: "index_bonuses_on_availability_end_date"
    t.index ["availability_start_date"], name: "index_bonuses_on_availability_start_date"
    t.index ["bonus_type"], name: "index_bonuses_on_bonus_type"
    t.index ["code"], name: "index_bonuses_on_code", unique: true
    t.index ["country"], name: "index_bonuses_on_country"
    t.index ["currency"], name: "index_bonuses_on_currency"
    t.index ["dsl_tag"], name: "index_bonuses_on_dsl_tag"
    t.index ["project"], name: "index_bonuses_on_project"
    t.index ["status"], name: "index_bonuses_on_status"
    t.index ["user_group"], name: "index_bonuses_on_user_group"
  end

  create_table "collect_bonuses", force: :cascade do |t|
    t.integer "bonus_id", null: false
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

  create_table "deposit_bonuses", force: :cascade do |t|
    t.integer "bonus_id", null: false
    t.decimal "deposit_amount_required", precision: 10, scale: 2
    t.decimal "bonus_percentage", precision: 5, scale: 2
    t.decimal "max_bonus_amount", precision: 15, scale: 2
    t.boolean "first_deposit_only", default: false
    t.boolean "recurring_eligible", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bonus_id"], name: "index_deposit_bonuses_on_bonus_id"
  end

  create_table "groups_update_bonuses", force: :cascade do |t|
    t.integer "bonus_id", null: false
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
    t.integer "bonus_id", null: false
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
    t.integer "bonus_id", null: false
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

  create_table "scheduler_bonuses", force: :cascade do |t|
    t.integer "bonus_id", null: false
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

  add_foreign_key "collect_bonuses", "bonuses"
  add_foreign_key "deposit_bonuses", "bonuses"
  add_foreign_key "groups_update_bonuses", "bonuses"
  add_foreign_key "input_coupon_bonuses", "bonuses"
  add_foreign_key "manual_bonuses", "bonuses"
  add_foreign_key "scheduler_bonuses", "bonuses"
end
