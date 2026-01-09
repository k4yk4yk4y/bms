class RetentionEmailBonus < ApplicationRecord
  belongs_to :retention_email
  belongs_to :bonus

  validates :bonus_id, uniqueness: { scope: :retention_email_id }
end
