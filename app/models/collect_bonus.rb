class CollectBonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = 'collect_bonuses'
  
  # Associations
  belongs_to :bonus

  # Validations
  validates :collection_type, presence: true, inclusion: { 
    in: %w[daily weekly monthly fixed_amount percentage] 
  }
  validates :collection_amount, presence: true, numericality: { greater_than: 0 }
  validates :collection_frequency, presence: true, inclusion: { 
    in: %w[daily weekly monthly once] 
  }
  validates :collection_limit, presence: true, numericality: { greater_than: 0 }
  validates :collected_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :collected_count_not_exceeds_limit

  # Scopes
  scope :by_type, ->(type) { where(collection_type: type) }
  scope :by_frequency, ->(frequency) { where(collection_frequency: frequency) }
  scope :available, -> { where('collected_count < collection_limit') }
  scope :completed, -> { where('collected_count >= collection_limit') }

  # Callbacks
  after_initialize :set_defaults

  # Instance methods
  def available?
    collected_count < collection_limit
  end

  def completed?
    collected_count >= collection_limit
  end

  def remaining_collections
    [collection_limit - collected_count, 0].max
  end

  def collection_percentage
    return 100 if collection_limit.zero?
    ((collected_count.to_f / collection_limit) * 100).round(2)
  end

  def can_collect_today?
    return false unless available?
    
    case collection_frequency
    when 'daily'
      true # Can collect every day
    when 'weekly'
      last_collection_more_than_week_ago?
    when 'monthly'
      last_collection_more_than_month_ago?
    when 'once'
      collected_count.zero?
    else
      false
    end
  end

  def collect!
    return false unless can_collect_today?
    
    increment!(:collected_count)
    true
  end

  def calculate_collection_amount(base_amount = nil)
    case collection_type
    when 'fixed_amount'
      collection_amount
    when 'percentage'
      return 0 unless base_amount
      base_amount * (collection_amount / 100)
    when 'daily', 'weekly', 'monthly'
      collection_amount
    else
      collection_amount
    end
  end

  def next_collection_available_at
    return nil unless available?
    
    case collection_frequency
    when 'daily'
      Date.current + 1.day
    when 'weekly'
      Date.current + 1.week
    when 'monthly'
      Date.current + 1.month
    when 'once'
      nil # One-time collection
    end
  end

  private

  def set_defaults
    self.collection_frequency ||= 'daily'
    self.collection_limit ||= 1
    self.collected_count ||= 0
  end

  def collected_count_not_exceeds_limit
    return unless collected_count && collection_limit
    
    if collected_count > collection_limit
      errors.add(:collected_count, 'cannot exceed collection limit')
    end
  end

  def last_collection_more_than_week_ago?
    # This would need to be implemented with a separate collections tracking table
    # For now, return true to allow collection
    true
  end

  def last_collection_more_than_month_ago?
    # This would need to be implemented with a separate collections tracking table
    # For now, return true to allow collection
    true
  end
end
