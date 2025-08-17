class AddCurrencyMinimumDepositsToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :currency_minimum_deposits, :text
  end
end
