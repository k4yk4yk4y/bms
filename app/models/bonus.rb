class Bonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = 'bonuses'
  
  # Status and type constants
  STATUSES = %w[draft active inactive expired].freeze
  BONUS_TYPES = %w[deposit input_coupon manual collection groups_update scheduler].freeze
  PROJECTS = %w[VOLNA ROX FRESH SOL JET IZZI LEGZO STARDA DRIP MONRO 1GO LEX GIZBO IRWIN FLAGMAN MARTIN P17 ANJUAN NAMASTE].freeze

  # Associations
  has_one :deposit_bonus, dependent: :destroy
  has_one :input_coupon_bonus, dependent: :destroy
  has_one :manual_bonus, dependent: :destroy
  has_one :collect_bonus, dependent: :destroy
  has_one :groups_update_bonus, dependent: :destroy
  has_one :scheduler_bonus, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :bonus_type, presence: true, inclusion: { in: BONUS_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :availability_start_date, presence: true
  validates :availability_end_date, presence: true
  validates :currency, presence: true, length: { maximum: 3 }
  validates :project, inclusion: { in: PROJECTS }, allow_blank: true
  validates :dsl_tag, length: { maximum: 255 }

  validate :end_date_after_start_date
  validate :valid_decimal_fields
  validate :minimum_deposit_for_appropriate_types

  # Scopes
  scope :draft, -> { where(status: 'draft') }
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :expired, -> { where(status: 'expired') }
  scope :by_type, ->(type) { where(bonus_type: type) }
  scope :by_currency, ->(currency) { where(currency: currency) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_project, ->(project) { where(project: project) }
  scope :by_dsl_tag, ->(dsl_tag) { where('dsl_tag LIKE ?', "%#{dsl_tag}%") }
  scope :available_now, -> { where('availability_start_date <= ? AND availability_end_date >= ?', Time.current, Time.current) }

  scope :deposit_type, -> { where(bonus_type: 'deposit') }
  scope :input_coupon_type, -> { where(bonus_type: 'input_coupon') }
  scope :manual_type, -> { where(bonus_type: 'manual') }
  scope :collection_type, -> { where(bonus_type: 'collection') }
  scope :groups_update_type, -> { where(bonus_type: 'groups_update') }
  scope :scheduler_type, -> { where(bonus_type: 'scheduler') }

  # Callbacks
  before_validation :generate_code, if: -> { code.blank? }

  # Instance methods
  def active?
    status == 'active' && available_now?
  end

  def available_now?
    Time.current.between?(availability_start_date, availability_end_date)
  end

  def expired?
    availability_end_date < Time.current
  end

  def type_specific_record
    case bonus_type
    when 'deposit'
      deposit_bonus
    when 'input_coupon'
      input_coupon_bonus
    when 'manual'
      manual_bonus
    when 'collection'
      collect_bonus
    when 'groups_update'
      groups_update_bonus
    when 'scheduler'
      scheduler_bonus
    end
  end

  def tags_array
    return [] if tags.blank?
    tags.split(',').map(&:strip)
  end

  def tags_array=(array)
    self.tags = array.join(', ')
  end

  def activate!
    update!(status: 'active')
  end

  def deactivate!
    update!(status: 'inactive')
  end

  def mark_as_expired!
    update!(status: 'expired')
  end

  private

  def end_date_after_start_date
    return unless availability_start_date && availability_end_date
    
    if availability_end_date <= availability_start_date
      errors.add(:availability_end_date, 'must be after start date')
    end
  end

  def valid_decimal_fields
    validate_decimal_field(:minimum_deposit)
    validate_decimal_field(:wager)
    validate_decimal_field(:maximum_winnings)
  end

  def validate_decimal_field(field)
    value = send(field)
    return if value.nil?
    
    if value < 0
      errors.add(field, 'must be greater than or equal to 0')
    end
  end

  def generate_code
    loop do
      self.code = "BONUS_#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(code: code)
    end
  end

  def minimum_deposit_for_appropriate_types
    # minimum_deposit не должно быть установлено для типов бонусов, которые не требуют депозита
    non_deposit_types = %w[input_coupon manual collection groups_update scheduler]
    
    if non_deposit_types.include?(bonus_type) && minimum_deposit.present?
      errors.add(:minimum_deposit, "не должно быть установлено для типа бонуса #{bonus_type}")
    end
    
    # Для депозитных бонусов minimum_deposit не должно дублироваться с deposit_amount_required
    if bonus_type == 'deposit' && minimum_deposit.present?
      errors.add(:minimum_deposit, "не должно использоваться для депозитных бонусов. Используйте настройки депозитного бонуса")
    end
  end

end
