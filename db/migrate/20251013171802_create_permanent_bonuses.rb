class CreatePermanentBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :permanent_bonuses do |t|
      t.string :project
      t.references :bonus, null: false, foreign_key: true

      t.timestamps
    end
  end
end
