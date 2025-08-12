class CreateCollectBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :collect_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :collection_type, null: false
      t.decimal :collection_amount, precision: 15, scale: 2
      t.string :collection_frequency, default: 'daily'
      t.integer :collection_limit, default: 1
      t.integer :collected_count, default: 0

      t.timestamps
    end

    # Index already created by t.references
    add_index :collect_bonuses, :collection_type
    add_index :collect_bonuses, :collection_frequency
  end
end
