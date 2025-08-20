class RemoveCurrencyFromBonuses < ActiveRecord::Migration[8.0]
  def change
    remove_column :bonuses, :currency, :string
  end
end
