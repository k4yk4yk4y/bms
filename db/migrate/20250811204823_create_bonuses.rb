class CreateBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :bonuses do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :bonus_type, null: false
      t.string :status, default: 'active'
      t.decimal :minimum_deposit, precision: 10, scale: 2
      t.decimal :wager, precision: 10, scale: 2
      t.decimal :maximum_winnings, precision: 15, scale: 2
      t.string :wagering_strategy
      t.datetime :availability_start_date, null: false
      t.datetime :availability_end_date, null: false
      t.string :user_group
      t.text :tags
      t.string :country
      t.string :currency, null: false
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end

    add_index :bonuses, :code, unique: true
    add_index :bonuses, :bonus_type
    add_index :bonuses, :status
    add_index :bonuses, :availability_start_date
    add_index :bonuses, :availability_end_date
    add_index :bonuses, :user_group
    add_index :bonuses, :country
    add_index :bonuses, :currency
  end
end
