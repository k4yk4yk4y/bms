class CreateBonusAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_audit_logs do |t|
      t.references :bonus, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.text :changes_data
      t.text :metadata

      t.timestamps
    end
  end
end
