class CreatePermanentBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :permanent_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.references :project, foreign_key: true

      t.timestamps
    end
  end
end
