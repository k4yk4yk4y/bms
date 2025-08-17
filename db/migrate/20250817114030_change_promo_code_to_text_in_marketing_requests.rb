class ChangePromoCodeToTextInMarketingRequests < ActiveRecord::Migration[8.0]
  def change
    change_column :marketing_requests, :promo_code, :text
  end
end
