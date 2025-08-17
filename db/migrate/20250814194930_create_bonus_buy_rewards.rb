class CreateBonusBuyRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_buy_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.decimal :buy_amount, precision: 15, scale: 2
      t.decimal :multiplier, precision: 5, scale: 2
      t.text :config

      t.timestamps
    end

    add_index :bonus_buy_rewards, :buy_amount
  end
end
