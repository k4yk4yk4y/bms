class DslTag < ApplicationRecord
  has_many :bonuses, dependent: :nullify

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }, allow_blank: true

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    ["name", "description", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["bonuses"]
  end

  # Scopes
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :with_bonuses, -> { joins(:bonuses).distinct }
  scope :without_bonuses, -> { left_joins(:bonuses).where(bonuses: { id: nil }) }

  # Instance methods
  def usage_count
    bonuses.count
  end

  def active_bonuses_count
    bonuses.active.count
  end

  def to_s
    name
  end
end
