class Project < ApplicationRecord
  has_many :permanent_bonuses, dependent: :destroy
  has_many :retention_chains, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    [ "name", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "permanent_bonuses" ]
  end
end
