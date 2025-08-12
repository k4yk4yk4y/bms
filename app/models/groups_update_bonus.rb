class GroupsUpdateBonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = "groups_update_bonuses"

  # Associations
  belongs_to :bonus

  # Validations
  validates :target_groups, presence: true
  validates :update_type, presence: true, inclusion: {
    in: %w[add_bonus remove_bonus modify_bonus bulk_apply]
  }
  validates :batch_size, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1000 }
  validates :processing_status, presence: true, inclusion: {
    in: %w[pending processing completed failed paused]
  }

  # Scopes
  scope :pending, -> { where(processing_status: "pending") }
  scope :processing, -> { where(processing_status: "processing") }
  scope :completed, -> { where(processing_status: "completed") }
  scope :failed, -> { where(processing_status: "failed") }
  scope :by_update_type, ->(type) { where(update_type: type) }

  # Callbacks
  after_initialize :set_defaults

  # Instance methods
  def target_groups_array
    return [] if target_groups.blank?
    JSON.parse(target_groups)
  rescue JSON::ParserError
    []
  end

  def target_groups_array=(array)
    self.target_groups = array.to_json
  end

  def update_parameters_hash
    return {} if update_parameters.blank?
    JSON.parse(update_parameters)
  rescue JSON::ParserError
    {}
  end

  def update_parameters_hash=(hash)
    self.update_parameters = hash.to_json
  end

  def pending?
    processing_status == "pending"
  end

  def processing?
    processing_status == "processing"
  end

  def completed?
    processing_status == "completed"
  end

  def failed?
    processing_status == "failed"
  end

  def paused?
    processing_status == "paused"
  end

  def can_start_processing?
    pending? || paused?
  end

  def start_processing!
    return false unless can_start_processing?
    update!(processing_status: "processing")
  end

  def complete_processing!
    update!(processing_status: "completed")
  end

  def fail_processing!(error_message = nil)
    params = update_parameters_hash
    params["error_message"] = error_message if error_message
    self.update_parameters_hash = params
    update!(processing_status: "failed")
  end

  def pause_processing!
    return false unless processing?
    update!(processing_status: "paused")
  end

  def resume_processing!
    return false unless paused?
    update!(processing_status: "processing")
  end

  def estimated_processing_time
    # Simple estimation based on target groups and batch size
    total_targets = target_groups_array.size
    return 0 if total_targets.zero?

    batches = (total_targets.to_f / batch_size).ceil
    batches * 30 # 30 seconds per batch (rough estimate)
  end

  def progress_percentage
    return 0 unless processing? || completed?
    return 100 if completed?

    # This would need to be implemented with actual progress tracking
    # For now, return a placeholder
    50
  end

  private

  def set_defaults
    self.batch_size ||= 100
    self.processing_status ||= "pending"
    self.target_groups ||= "[]"
    self.update_parameters ||= "{}"
  end
end
