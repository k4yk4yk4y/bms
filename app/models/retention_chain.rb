class RetentionChain < ApplicationRecord
  include Auditable

  STATUSES = %w[draft active archived].freeze

  belongs_to :project, optional: true
  belongs_to :creator, polymorphic: true, foreign_key: "created_by", foreign_type: "created_by_type", optional: true
  belongs_to :updater, polymorphic: true, foreign_key: "updated_by", foreign_type: "updated_by_type", optional: true

  has_many :retention_emails, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :name, presence: true, unless: :draft?
  validates :project_id, presence: true, unless: :draft?

  before_validation :set_launch_date_if_activating

  def draft?
    status == "draft"
  end

  def active?
    status == "active"
  end

  def display_name
    name.presence || "Draft chain ##{id}"
  end

  private

  def set_launch_date_if_activating
    return unless status == "active" && launch_date.blank?

    self.launch_date = Time.current
  end
end
