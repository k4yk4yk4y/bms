class AddLimitationsToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :no_more, :text, comment: 'Usage limitation string (e.g., "1 per day", "3 per week")'
    add_column :bonuses, :totally_no_more, :integer, comment: 'Total limit of activations across all players'
  end
end
