class AddMaximumWinningsTypeToBonus < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :maximum_winnings_type, :string, default: 'multiplier', null: false
  end
end
