class AddCurrencyAmountsToBonusRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :bonus_rewards, :currency_amounts, :text
  end
end
