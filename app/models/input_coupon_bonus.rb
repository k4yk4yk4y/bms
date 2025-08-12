class InputCouponBonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = 'input_coupon_bonuses'
  
  # Associations
  belongs_to :bonus

  # Validations
  validates :coupon_code, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :usage_limit, presence: true, numericality: { greater_than: 0 }
  validates :usage_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :expires_at, presence: true

  validate :usage_count_not_exceeds_limit
  validate :expires_at_in_future

  # Scopes
  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :available, -> { active.where('usage_count < usage_limit') }

  # Callbacks
  after_initialize :set_defaults

  # Instance methods
  def available?
    !expired? && !usage_limit_reached?
  end

  def expired?
    expires_at <= Time.current
  end

  def usage_limit_reached?
    usage_count >= usage_limit
  end

  def remaining_uses
    usage_limit - usage_count
  end

  def use_coupon!
    return false unless available?
    
    increment!(:usage_count)
    true
  end

  def usage_percentage
    return 0 if usage_limit.zero?
    ((usage_count.to_f / usage_limit) * 100).round(2)
  end

  def days_until_expiry
    return 0 if expired?
    ((expires_at - Time.current) / 1.day).ceil
  end

  private

  def set_defaults
    self.usage_limit ||= 1
    self.usage_count ||= 0
    self.single_use = true if single_use.nil?
    self.expires_at ||= 30.days.from_now
  end

  def usage_count_not_exceeds_limit
    return unless usage_count && usage_limit
    
    if usage_count > usage_limit
      errors.add(:usage_count, 'cannot exceed usage limit')
    end
  end

  def expires_at_in_future
    return unless expires_at
    
    if expires_at <= Time.current
      errors.add(:expires_at, 'must be in the future')
    end
  end
end
