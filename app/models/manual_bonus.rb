class ManualBonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = 'manual_bonuses'
  
  # Associations
  belongs_to :bonus

  # Validations
  validates :approval_required, inclusion: { in: [true, false] }
  validates :auto_apply, inclusion: { in: [true, false] }

  validate :auto_apply_requires_no_approval

  # Scopes
  scope :requiring_approval, -> { where(approval_required: true) }
  scope :auto_applicable, -> { where(auto_apply: true) }

  # Callbacks
  after_initialize :set_defaults

  # Instance methods
  def can_be_applied_automatically?
    auto_apply && !approval_required
  end

  def requires_manual_intervention?
    approval_required || !auto_apply
  end

  def conditions_array
    return [] if conditions.blank?
    JSON.parse(conditions)
  rescue JSON::ParserError
    []
  end

  def conditions_array=(array)
    self.conditions = array.to_json
  end

  def add_condition(condition)
    current_conditions = conditions_array
    current_conditions << condition
    self.conditions_array = current_conditions
  end

  def remove_condition(condition)
    current_conditions = conditions_array
    current_conditions.delete(condition)
    self.conditions_array = current_conditions
  end

  def meets_conditions?(user_data = {})
    return true if conditions_array.empty?
    
    conditions_array.all? do |condition|
      evaluate_condition(condition, user_data)
    end
  end

  private

  def set_defaults
    self.approval_required = true if approval_required.nil?
    self.auto_apply = false if auto_apply.nil?
    self.conditions ||= '[]'
  end

  def auto_apply_requires_no_approval
    if auto_apply && approval_required
      errors.add(:auto_apply, 'cannot be true when approval is required')
    end
  end

  def evaluate_condition(condition, user_data)
    # Simple condition evaluation - can be extended based on business logic
    return true unless condition.is_a?(Hash)
    
    field = condition['field']
    operator = condition['operator']
    value = condition['value']
    
    return true unless field && operator && value
    
    user_value = user_data[field.to_sym] || user_data[field]
    
    case operator
    when 'equals'
      user_value == value
    when 'greater_than'
      user_value.to_f > value.to_f
    when 'less_than'
      user_value.to_f < value.to_f
    when 'contains'
      user_value.to_s.include?(value.to_s)
    else
      true
    end
  end
end
