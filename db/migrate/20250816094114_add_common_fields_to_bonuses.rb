class AddCommonFieldsToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :currencies, :text, comment: 'JSON array of supported currencies'
    add_column :bonuses, :groups, :text, comment: 'JSON array of target user groups'
  end
end
