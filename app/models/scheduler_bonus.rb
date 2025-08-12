class SchedulerBonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = "scheduler_bonuses"

  # Associations
  belongs_to :bonus

  # Validations
  validates :schedule_type, presence: true, inclusion: {
    in: %w[recurring one_time cron_based interval_based]
  }
  validates :execution_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_executions, numericality: { greater_than: 0 }, allow_blank: true

  validate :validate_cron_expression
  validate :validate_execution_limits

  # Scopes
  scope :recurring, -> { where(schedule_type: "recurring") }
  scope :one_time, -> { where(schedule_type: "one_time") }
  scope :cron_based, -> { where(schedule_type: "cron_based") }
  scope :due_for_execution, -> { where("next_run_at <= ?", Time.current) }
  scope :active, -> { where("max_executions IS NULL OR execution_count < max_executions") }

  # Callbacks
  after_initialize :set_defaults
  before_save :calculate_next_run_time

  # Instance methods
  def due_for_execution?
    return false unless next_run_at
    next_run_at <= Time.current
  end

  def can_execute?
    due_for_execution? && !execution_limit_reached?
  end

  def execution_limit_reached?
    return false unless max_executions
    execution_count >= max_executions
  end

  def remaining_executions
    return Float::INFINITY unless max_executions
    [ max_executions - execution_count, 0 ].max
  end

  def execute!
    return false unless can_execute?

    increment!(:execution_count)
    update!(last_run_at: Time.current)
    calculate_and_update_next_run_time

    true
  end

  def execution_percentage
    return 0 unless max_executions && max_executions > 0
    ((execution_count.to_f / max_executions) * 100).round(2)
  end

  def time_until_next_execution
    return nil unless next_run_at
    return 0 if next_run_at <= Time.current

    next_run_at - Time.current
  end

  def schedule_description
    case schedule_type
    when "recurring"
      "Recurring every #{parse_interval_from_cron}"
    when "one_time"
      "One-time execution at #{next_run_at&.strftime('%Y-%m-%d %H:%M')}"
    when "cron_based"
      "Cron: #{cron_expression}"
    when "interval_based"
      "Interval-based execution"
    else
      "Unknown schedule type"
    end
  end

  def is_active?
    !execution_limit_reached?
  end

  def next_execution_formatted
    return "Not scheduled" unless next_run_at
    return "Overdue" if next_run_at <= Time.current

    next_run_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  private

  def set_defaults
    self.execution_count ||= 0
    self.schedule_type ||= "one_time"

    if next_run_at.blank? && schedule_type == "one_time"
      self.next_run_at = 1.hour.from_now
    end
  end

  def validate_cron_expression
    return unless schedule_type == "cron_based"
    return if cron_expression.blank?

    # Basic cron validation (5 or 6 fields)
    parts = cron_expression.split(" ")
    unless [ 5, 6 ].include?(parts.length)
      errors.add(:cron_expression, "must have 5 or 6 fields (minute hour day month weekday [year])")
    end
  end

  def validate_execution_limits
    return unless execution_count && max_executions

    if execution_count > max_executions
      errors.add(:execution_count, "cannot exceed maximum executions")
    end
  end

  def calculate_next_run_time
    return unless schedule_type && (next_run_at.blank? || next_run_at_changed?)

    case schedule_type
    when "one_time"
      # next_run_at should be set manually
    when "recurring", "interval_based"
      calculate_next_recurring_time
    when "cron_based"
      calculate_next_cron_time
    end
  end

  def calculate_and_update_next_run_time
    case schedule_type
    when "one_time"
      self.next_run_at = nil # One-time execution, no next run
    when "recurring", "interval_based"
      calculate_next_recurring_time
    when "cron_based"
      calculate_next_cron_time
    end

    save! if changed?
  end

  def calculate_next_recurring_time
    # Simple daily recurrence as default
    # This can be extended to support different intervals
    self.next_run_at = (last_run_at || Time.current) + 1.day
  end

  def calculate_next_cron_time
    return unless cron_expression.present?

    # Basic cron parsing - in a real application, use a gem like 'cron_parser'
    # For now, set to next hour as a placeholder
    self.next_run_at = 1.hour.from_now
  end

  def parse_interval_from_cron
    # Simple parsing for display purposes
    return "day" if cron_expression&.start_with?("0 0")
    return "hour" if cron_expression&.include?("* *")
    "interval"
  end
end
