class CreateDepositBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :deposit_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.decimal :deposit_amount_required, precision: 10, scale: 2
      t.decimal :bonus_percentage, precision: 5, scale: 2
      t.decimal :max_bonus_amount, precision: 15, scale: 2
      t.boolean :first_deposit_only, default: false
      t.boolean :recurring_eligible, default: false

      t.timestamps
    end

    # Index already created by t.references
  end
end
