class AddDepositPercentageToBonusTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :bonus_templates, :deposit_percentage, :decimal
  end
end
