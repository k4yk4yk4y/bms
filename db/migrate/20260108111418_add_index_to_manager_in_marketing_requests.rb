class AddIndexToManagerInMarketingRequests < ActiveRecord::Migration[8.0]
  def change
    # Add index on manager field for better query performance when filtering by manager
    add_index :marketing_requests, :manager, if_not_exists: true
  end
end
