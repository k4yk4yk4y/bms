class AddDescriptionToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :description, :text
  end
end
