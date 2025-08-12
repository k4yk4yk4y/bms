class FixForeignKeyReferences < ActiveRecord::Migration[8.0]
  def change
    # Remove existing foreign keys
    remove_foreign_key "collect_bonuses", "bonus"
    remove_foreign_key "deposit_bonuses", "bonus"
    remove_foreign_key "groups_update_bonuses", "bonus"
    remove_foreign_key "input_coupon_bonuses", "bonus"
    remove_foreign_key "manual_bonuses", "bonus"
    remove_foreign_key "scheduler_bonuses", "bonus"

    # Add correct foreign keys pointing to "bonuses" table
    add_foreign_key "collect_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "deposit_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "groups_update_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "input_coupon_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "manual_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "scheduler_bonuses", "bonuses", column: "bonus_id"
  end
end
