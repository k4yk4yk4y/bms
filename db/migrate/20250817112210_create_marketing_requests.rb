class CreateMarketingRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :marketing_requests do |t|
      t.string :manager, null: false
      t.text :platform
      t.string :partner_email, null: false
      t.string :promo_code, null: false
      t.string :stag, null: false
      t.datetime :activation_date
      t.string :status, default: 'pending', null: false
      t.string :request_type, null: false

      t.timestamps
    end

    add_index :marketing_requests, :promo_code, unique: true
    add_index :marketing_requests, :stag, unique: true
    add_index :marketing_requests, :status
    add_index :marketing_requests, :request_type
    add_index :marketing_requests, :partner_email
  end
end
