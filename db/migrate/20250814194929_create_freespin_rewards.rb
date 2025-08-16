class CreateFreespinRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :freespin_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.integer :spins_count, null: false
      t.text :game_restrictions
      t.text :config

      t.timestamps
    end
    
    add_index :freespin_rewards, :spins_count
  end
end
