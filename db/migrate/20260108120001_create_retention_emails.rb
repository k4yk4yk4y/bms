class CreateRetentionEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :retention_emails do |t|
      t.references :retention_chain, null: false, foreign_key: true
      t.string :subject
      t.string :preheader
      t.string :header
      t.text :body
      t.string :send_timing
      t.text :description
      t.string :status, null: false, default: "draft"
      t.datetime :launch_date
      t.integer :position
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end

    add_index :retention_emails, :status
    add_index :retention_emails, :launch_date
    add_index :retention_emails, [ :retention_chain_id, :position ]
  end
end
