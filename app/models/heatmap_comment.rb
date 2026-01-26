class HeatmapComment < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :body, presence: true, length: { maximum: 2000 }

  def self.ransackable_attributes(auth_object = nil)
    [ "body", "created_at", "date", "id", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user" ]
  end
end
