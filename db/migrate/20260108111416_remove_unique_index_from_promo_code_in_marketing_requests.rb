class RemoveUniqueIndexFromPromoCodeInMarketingRequests < ActiveRecord::Migration[8.0]
  def change
    # Remove unique constraint since promo_code can contain multiple codes separated by commas
    remove_index :marketing_requests, :promo_code, if_exists: true
    # Add non-unique index for search performance
    add_index :marketing_requests, :promo_code, if_not_exists: true
  end
end
