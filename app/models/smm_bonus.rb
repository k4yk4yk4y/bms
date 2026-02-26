class SmmBonus < ApplicationRecord
  include Auditable

  STATUSES = {
    "draft" => "DRAFT",
    "ready" => "READY",
    "checked" => "CHECKED / ACTIVE"
  }.freeze

  belongs_to :smm_month_project
  belongs_to :smm_preset, optional: true
  belongs_to :bonus, optional: true
  belongs_to :manager, class_name: "User", optional: true

  attribute :currencies, :json, default: []

  validates :status, presence: true, inclusion: { in: STATUSES.keys }
  validates :group, inclusion: { in: SmmPreset::GROUPS.keys }, allow_blank: true

  scope :ordered, -> { order(created_at: :asc, id: :asc) }

  def status_label
    STATUSES[status] || status
  end

  def currencies
    super || []
  end

  def currencies=(value)
    values = case value
    when String
               value.split(/[;,]/)
    when Array
               value
    else
               Array(value)
    end

    super(values.map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq)
  end

  def activation_limit_label
    return "Unlimited" if activation_limit.blank?

    "#{activation_limit} acts"
  end

  def wager_label
    return "-" if wager_multiplier.blank?

    "x#{format_number(wager_multiplier)}"
  end

  def max_win_label
    return "-" if max_win_multiplier.blank?

    "x#{format_number(max_win_multiplier)}"
  end

  def group_label
    SmmPreset::GROUPS[group] || group
  end

  def duplicate_attributes
    attributes.except(
      "id",
      "smm_month_project_id",
      "code",
      "bonus_id",
      "created_at",
      "updated_at",
      "created_by",
      "created_by_type",
      "updated_by",
      "updated_by_type"
    ).merge(
      "status" => "draft",
      "code" => nil,
      "bonus_id" => nil
    )
  end

  private

  def format_number(value)
    value.to_i == value ? value.to_i : value
  end
end
