class AddTitleToBonusCodeRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :bonus_code_rewards, :title, :string
  end
end
