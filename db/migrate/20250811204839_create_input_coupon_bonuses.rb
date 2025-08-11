class CreateInputCouponBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :input_coupon_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :coupon_code, null: false
      t.integer :usage_limit, default: 1
      t.integer :usage_count, default: 0
      t.datetime :expires_at
      t.boolean :single_use, default: true

      t.timestamps
    end

    # Index already created by t.references
    add_index :input_coupon_bonuses, :coupon_code, unique: true
    add_index :input_coupon_bonuses, :expires_at
  end
end
