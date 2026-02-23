class SmmMonthProject < ApplicationRecord
  include Auditable

  belongs_to :smm_month
  belongs_to :project

  has_many :smm_bonuses, dependent: :destroy

  validates :project_id, uniqueness: { scope: :smm_month_id }

  def display_name
    project&.name || "Project"
  end
end
