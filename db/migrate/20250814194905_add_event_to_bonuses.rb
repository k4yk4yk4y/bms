class AddEventToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :event, :string
    
    # Заполняем event на основе существующих bonus_type
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE bonuses SET event = bonus_type WHERE bonus_type IS NOT NULL;
        SQL
      end
    end
    
    change_column_null :bonuses, :event, false
    add_index :bonuses, :event
  end
end
