class AddFieldsToBonusRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :bonus_rewards, :wager, :float, default: 0.0
    add_column :bonus_rewards, :max_win_value, :decimal
    add_column :bonus_rewards, :max_win_type, :string, default: "fixed"
    add_column :bonus_rewards, :available, :integer
    add_column :bonus_rewards, :code, :string
    add_column :bonus_rewards, :user_can_have_duplicates, :boolean, default: false
    add_column :bonus_rewards, :stag, :string
  end
end
