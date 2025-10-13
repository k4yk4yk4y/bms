class PermanentBonus < ApplicationRecord
  belongs_to :bonus
  belongs_to :project

  validates :project_id, presence: true
  validates :bonus_id, uniqueness: { scope: :project_id, message: "has already been added to this project" }

  def self.ransackable_attributes(auth_object = nil)
    [ "project_id", "bonus_id", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "bonus", "project" ]
  end
end
