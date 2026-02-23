class AddCurrencyMaximumAmountsToBonusRewards < ActiveRecord::Migration[7.0]
  def change
    add_column :bonus_rewards, :currency_maximum_amounts, :text
  end
end
