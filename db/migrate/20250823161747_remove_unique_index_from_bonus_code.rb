class RemoveUniqueIndexFromBonusCode < ActiveRecord::Migration[8.0]
  def change
    remove_index :bonuses, :code
    add_index :bonuses, :code
  end
end
