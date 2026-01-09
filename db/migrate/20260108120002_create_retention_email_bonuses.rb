class CreateRetentionEmailBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :retention_email_bonuses do |t|
      t.references :retention_email, null: false, foreign_key: true
      t.references :bonus, null: false, foreign_key: true

      t.timestamps
    end

    add_index :retention_email_bonuses, [ :retention_email_id, :bonus_id ], unique: true,
              name: "index_retention_email_bonuses_on_email_and_bonus"
  end
end
