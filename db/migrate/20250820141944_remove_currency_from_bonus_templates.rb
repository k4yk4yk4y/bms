class RemoveCurrencyFromBonusTemplates < ActiveRecord::Migration[8.0]
  def change
    remove_column :bonus_templates, :currency, :string
  end
end
