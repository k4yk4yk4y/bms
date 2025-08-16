class CompPointReward < ApplicationRecord
  belongs_to :bonus

  # Serialize config as JSON for additional parameters
  serialize :config, coder: JSON

  validates :issue_chargeable_award, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :issue_persistent_award, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :title, presence: true

  # Validate that at least one award type is present
  validate :at_least_one_award_present

  # Config accessors for common parameters
  def config
    super || {}
  end

  # Helper methods
  def formatted_chargeable_award
    issue_chargeable_award.present? ? "#{issue_chargeable_award} расходуемых" : "0"
  end

  def formatted_persistent_award
    issue_persistent_award.present? ? "#{issue_persistent_award} статусных" : "0"
  end

  def total_points
    (issue_chargeable_award || 0) + (issue_persistent_award || 0)
  end

  private

  def at_least_one_award_present
    if issue_chargeable_award.blank? && issue_persistent_award.blank?
      errors.add(:base, "Должен быть указан хотя бы один тип баллов (расходуемые или статусные)")
    end
  end
end
