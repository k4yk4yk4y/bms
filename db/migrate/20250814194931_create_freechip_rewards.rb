class CreateFreechipRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :freechip_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.decimal :chip_value, precision: 15, scale: 2, null: false
      t.integer :chips_count, null: false
      t.text :config

      t.timestamps
    end
    
    add_index :freechip_rewards, :chip_value
  end
end
