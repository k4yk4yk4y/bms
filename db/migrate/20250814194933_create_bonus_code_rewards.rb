class CreateBonusCodeRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_code_rewards do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :code, null: false
      t.string :code_type, null: false
      t.text :config

      t.timestamps
    end
    
    add_index :bonus_code_rewards, :code, unique: true
    add_index :bonus_code_rewards, :code_type
  end
end
