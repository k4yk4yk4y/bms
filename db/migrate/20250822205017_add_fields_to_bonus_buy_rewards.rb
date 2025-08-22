class AddFieldsToBonusBuyRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :bonus_buy_rewards, :games, :text, default: [].to_yaml
    add_column :bonus_buy_rewards, :bet_level, :float
    add_column :bonus_buy_rewards, :max_win_value, :decimal
    add_column :bonus_buy_rewards, :max_win_type, :string, default: "fixed"
    add_column :bonus_buy_rewards, :available, :integer
    add_column :bonus_buy_rewards, :code, :string
    add_column :bonus_buy_rewards, :stag, :string
  end
end
