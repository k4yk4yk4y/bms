class CreateCompPointRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :comp_point_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.integer :points_amount, null: false
      t.decimal :multiplier, precision: 5, scale: 2
      t.text :config

      t.timestamps
    end
    
    add_index :comp_point_rewards, :points_amount
  end
end
