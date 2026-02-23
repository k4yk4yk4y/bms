class SmmMonth < ApplicationRecord
  include Auditable

  has_many :smm_month_projects, dependent: :destroy
  has_many :projects, through: :smm_month_projects
  has_many :smm_bonuses, through: :smm_month_projects

  validates :name, presence: true
  validates :starts_on, presence: true

  scope :ordered, -> { order(starts_on: :desc, created_at: :desc) }

  def display_name
    name.presence || starts_on.strftime("%B %Y")
  end
end
