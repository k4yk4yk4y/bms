class CreateBonusRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :reward_type, null: false
      t.decimal :amount, precision: 15, scale: 2
      t.decimal :percentage, precision: 5, scale: 2
      t.text :config

      t.timestamps
    end

    add_index :bonus_rewards, :reward_type
    add_index :bonus_rewards, [ :bonus_id, :reward_type ]
  end
end
