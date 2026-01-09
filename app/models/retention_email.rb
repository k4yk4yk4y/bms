class RetentionEmail < ApplicationRecord
  include Auditable

  STATUSES = %w[draft active archived].freeze

  belongs_to :retention_chain, counter_cache: true
  belongs_to :creator, class_name: "User", foreign_key: "created_by", optional: true
  belongs_to :updater, class_name: "User", foreign_key: "updated_by", optional: true

  has_many :retention_email_bonuses, dependent: :destroy
  has_many :bonuses, through: :retention_email_bonuses

  has_many_attached :images

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :subject, presence: true, unless: :draft?
  validates :header, presence: true, unless: :draft?
  validate :bonuses_match_chain_project

  before_validation :set_launch_date_if_activating
  before_create :assign_position

  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  def draft?
    status == "draft"
  end

  def active?
    status == "active"
  end

  def display_subject
    subject.presence || "Draft email ##{id}"
  end

  private

  def set_launch_date_if_activating
    return unless status == "active" && launch_date.blank?

    self.launch_date = Time.current
  end

  def assign_position
    return if position.present?

    max_position = retention_chain.retention_emails.maximum(:position)
    self.position = max_position.to_i + 1
  end

  def bonuses_match_chain_project
    return if bonuses.empty?

    chain_project = retention_chain.project
    if chain_project.nil?
      errors.add(:bonuses, "must match chain project")
      return
    end

    invalid_bonus = bonuses.detect do |bonus|
      bonus.project.to_s.casecmp?(chain_project.name.to_s) == false
    end
    return unless invalid_bonus

    errors.add(:bonuses, "must match chain project")
  end
end
