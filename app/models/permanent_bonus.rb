class PermanentBonus < ApplicationRecord
  belongs_to :bonus

  validates :project, presence: true
  validates :bonus_id, uniqueness: { scope: :project, message: "has already been added to this project" }

  def self.ransackable_attributes(auth_object = nil)
    ["project", "bonus_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["bonus"]
  end
end
