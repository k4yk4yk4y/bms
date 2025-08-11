class CreateGroupsUpdateBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :groups_update_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.text :target_groups, null: false
      t.string :update_type, null: false
      t.text :update_parameters
      t.integer :batch_size, default: 100
      t.string :processing_status, default: 'pending'

      t.timestamps
    end

    # Index already created by t.references
    add_index :groups_update_bonuses, :update_type
    add_index :groups_update_bonuses, :processing_status
  end
end
