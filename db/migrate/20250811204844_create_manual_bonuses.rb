class CreateManualBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :manual_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.text :admin_notes
      t.boolean :approval_required, default: true
      t.boolean :auto_apply, default: false
      t.text :conditions

      t.timestamps
    end

    # Index already created by t.references
    add_index :manual_bonuses, :approval_required
    add_index :manual_bonuses, :auto_apply
  end
end
