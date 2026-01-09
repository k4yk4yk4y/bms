class CreateRetentionChains < ActiveRecord::Migration[8.0]
  def change
    create_table :retention_chains do |t|
      t.string :name
      t.references :project, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.datetime :launch_date
      t.integer :retention_emails_count, null: false, default: 0
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end

    add_index :retention_chains, :status
    add_index :retention_chains, :launch_date
    add_index :retention_chains, :created_by
  end
end
