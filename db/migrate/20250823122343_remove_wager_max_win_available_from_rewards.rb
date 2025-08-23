class RemoveWagerMaxWinAvailableFromRewards < ActiveRecord::Migration[8.0]
  def change
    # Remove wager, max_win_value, max_win_type, available from bonus_rewards
    remove_column :bonus_rewards, :wager, :float
    remove_column :bonus_rewards, :max_win_value, :decimal
    remove_column :bonus_rewards, :max_win_type, :string
    remove_column :bonus_rewards, :available, :integer

    # Remove max_win_value, max_win_type, available from freespin_rewards
    remove_column :freespin_rewards, :max_win_value, :decimal
    remove_column :freespin_rewards, :max_win_type, :string
    remove_column :freespin_rewards, :available, :integer

    # Remove max_win_value, max_win_type, available from bonus_buy_rewards
    remove_column :bonus_buy_rewards, :max_win_value, :decimal
    remove_column :bonus_buy_rewards, :max_win_type, :string
    remove_column :bonus_buy_rewards, :available, :integer
  end
end
