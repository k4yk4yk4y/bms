class AddMissingColumnsToRewards < ActiveRecord::Migration[8.0]
  def change
    # Добавляем недостающие колонки в bonus_rewards
    add_column :bonus_rewards, :max_win_value, :decimal, precision: 15, scale: 2
    add_column :bonus_rewards, :max_win_type, :string, default: 'fixed'
    add_column :bonus_rewards, :available, :integer

    # Добавляем недостающие колонки в freespin_rewards
    add_column :freespin_rewards, :max_win_value, :decimal, precision: 15, scale: 2
    add_column :freespin_rewards, :max_win_type, :string, default: 'fixed'
    add_column :freespin_rewards, :available, :integer

    # Добавляем недостающие колонки в bonus_buy_rewards
    add_column :bonus_buy_rewards, :max_win_value, :decimal, precision: 15, scale: 2
    add_column :bonus_buy_rewards, :max_win_type, :string, default: 'fixed'
    add_column :bonus_buy_rewards, :available, :integer
  end
end
