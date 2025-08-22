class AddTitleToCompPointRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :comp_point_rewards, :title, :string
  end
end
