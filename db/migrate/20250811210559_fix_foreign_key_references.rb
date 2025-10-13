class FixForeignKeyReferences < ActiveRecord::Migration[8.0]
  def change
    # Remove existing foreign keys if they exist
    remove_foreign_key "collect_bonuses", "bonuses" if foreign_key_exists?("collect_bonuses", "bonuses")
    remove_foreign_key "deposit_bonuses", "bonuses" if foreign_key_exists?("deposit_bonuses", "bonuses")
    remove_foreign_key "groups_update_bonuses", "bonuses" if foreign_key_exists?("groups_update_bonuses", "bonuses")
    remove_foreign_key "input_coupon_bonuses", "bonuses" if foreign_key_exists?("input_coupon_bonuses", "bonuses")
    remove_foreign_key "manual_bonuses", "bonuses" if foreign_key_exists?("manual_bonuses", "bonuses")
    remove_foreign_key "scheduler_bonuses", "bonuses" if foreign_key_exists?("scheduler_bonuses", "bonuses")

    # Add correct foreign keys pointing to "bonuses" table
    add_foreign_key "collect_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "deposit_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "groups_update_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "input_coupon_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "manual_bonuses", "bonuses", column: "bonus_id"
    add_foreign_key "scheduler_bonuses", "bonuses", column: "bonus_id"
  end
end
