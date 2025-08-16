class CreateMaterialPrizeRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :material_prize_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :prize_name, null: false
      t.decimal :prize_value, precision: 15, scale: 2
      t.text :config

      t.timestamps
    end
    
    add_index :material_prize_rewards, :prize_name
  end
end
