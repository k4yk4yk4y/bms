class Bonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = "bonuses"

  # Status and type constants
  STATUSES = %w[draft active inactive expired].freeze
  EVENT_TYPES = %w[deposit input_coupon manual collection groups_update scheduler].freeze
  PROJECTS = %w[VOLNA ROX FRESH SOL JET IZZI LEGZO STARDA DRIP MONRO 1GO LEX GIZBO IRWIN FLAGMAN MARTIN P17 ANJUAN NAMASTE].freeze

  # New reward associations
  has_many :bonus_rewards, dependent: :destroy
  has_many :freespin_rewards, dependent: :destroy
  has_many :bonus_buy_rewards, dependent: :destroy
  has_many :comp_point_rewards, dependent: :destroy
  has_many :bonus_code_rewards, dependent: :destroy
  has_many :freechip_rewards, dependent: :destroy
  has_many :bonus_code_rewards, dependent: :destroy
  has_many :material_prize_rewards, dependent: :destroy
  has_many :comp_point_rewards, dependent: :destroy



  # Store JSON data
  serialize :currencies, coder: JSON
  serialize :groups, coder: JSON

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :event, presence: true, inclusion: { in: EVENT_TYPES }
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
  scope :draft, -> { where(status: "draft") }
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :expired, -> { where(status: "expired") }
  scope :by_event, ->(event) { where(event: event) }
  scope :by_currency, ->(currency) { where(currency: currency) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_project, ->(project) { where(project: project) }
  scope :by_dsl_tag, ->(dsl_tag) { where("dsl_tag LIKE ?", "%#{dsl_tag}%") }
  scope :available_now, -> { where("availability_start_date <= ? AND availability_end_date >= ?", Time.current, Time.current) }

  scope :deposit_event, -> { where(event: "deposit") }
  scope :input_coupon_event, -> { where(event: "input_coupon") }
  scope :manual_event, -> { where(event: "manual") }
  scope :collection_event, -> { where(event: "collection") }
  scope :groups_update_event, -> { where(event: "groups_update") }
  scope :scheduler_event, -> { where(event: "scheduler") }

  # Callbacks
  before_validation :generate_code, if: -> { code.blank? }

  # Instance methods
  def active?
    status == "active" && available_now?
  end

  def available_now?
    Time.current.between?(availability_start_date, availability_end_date)
  end

  def expired?
    availability_end_date < Time.current
  end

  # Legacy method - deprecated, use new reward system
  def type_specific_record
    # This method is deprecated. Use the new reward associations:
    # bonus_rewards, freespin_rewards, bonus_buy_rewards, etc.
    nil
  end

  # New methods for working with rewards
  def all_rewards
    [
      bonus_rewards,
      freespin_rewards,
      bonus_buy_rewards,
      freechip_rewards,
      bonus_code_rewards,
      material_prize_rewards,
      comp_point_rewards
    ].flatten
  end

  def has_rewards?
    all_rewards.any?
  end

  def reward_types
    types = []
    types << 'bonus' if bonus_rewards.any?
    types << 'freespins' if freespin_rewards.any?
    types << 'bonus_buy' if bonus_buy_rewards.any?
    types << 'freechips' if freechip_rewards.any?
    types << 'bonus_code' if bonus_code_rewards.any?
    types << 'material_prize' if material_prize_rewards.any?
    types << 'comp_point' if comp_point_rewards.any?
    types
  end

  # Methods to get data from rewards for display in table
  def display_code
    # Try to get code from first reward, fallback to bonus code
    first_reward = all_rewards.first
    first_reward&.code || code
  end

  def display_currency
    # Try to get currency from first reward, fallback to bonus currency
    first_reward = all_rewards.first
    if first_reward&.respond_to?(:currencies) && first_reward.currencies.present?
      first_reward.currencies.is_a?(Array) ? first_reward.currencies.join(', ') : first_reward.currencies
    else
      currency
    end
  end

  def display_country
    # Try to get country from first reward, fallback to bonus country
    first_reward = all_rewards.first
    if first_reward&.respond_to?(:current_ip_country) && first_reward.current_ip_country.present?
      first_reward.current_ip_country
    elsif first_reward&.respond_to?(:profile_country) && first_reward.profile_country.present?
      first_reward.profile_country
    elsif first_reward&.respond_to?(:last_login_country) && first_reward.last_login_country.present?
      first_reward.last_login_country
    else
      country
    end
  end

  def display_tags
    # Try to get tags from first reward, fallback to bonus tags
    first_reward = all_rewards.first
    if first_reward&.respond_to?(:tags) && first_reward.tags.present?
      first_reward.tags.is_a?(Array) ? first_reward.tags.join(', ') : first_reward.tags
    else
      tags
    end
  end

  def display_user_group
    # Try to get groups from first reward, fallback to bonus user_group
    first_reward = all_rewards.first
    if first_reward&.respond_to?(:groups) && first_reward.groups.present?
      first_reward.groups.is_a?(Array) ? first_reward.groups.join(', ') : first_reward.groups
    else
      user_group
    end
  end

  def tags_array
    return [] if tags.blank?
    tags.split(",").map(&:strip)
  end

  def tags_array=(array)
    self.tags = array.join(", ")
  end

  # Currencies methods
  def currencies
    super || []
  end

  def currencies=(value)
    if value.is_a?(Array)
      super(value.reject(&:blank?))
    elsif value.is_a?(String)
      super(value.split(',').map(&:strip).reject(&:blank?))
    else
      super(value)
    end
  end

  def formatted_currencies
    currencies.join(', ') if currencies.any?
  end

  # Groups methods
  def groups
    super || []
  end

  def groups=(value)
    if value.is_a?(Array)
      super(value.reject(&:blank?))
    elsif value.is_a?(String)
      super(value.split(',').map(&:strip).reject(&:blank?))
    else
      super(value)
    end
  end

  def formatted_groups
    groups.join(', ') if groups.any?
  end

  # Limitation methods
  def formatted_no_more
    no_more.present? ? no_more : 'No limit'
  end

  def formatted_totally_no_more
    totally_no_more.present? ? "#{totally_no_more} total" : 'Unlimited'
  end

  def activate!
    update!(status: "active")
  end

  def deactivate!
    update!(status: "inactive")
  end

  def mark_as_expired!
    update!(status: "expired")
  end

  private

  def end_date_after_start_date
    return unless availability_start_date && availability_end_date

    if availability_end_date <= availability_start_date
      errors.add(:availability_end_date, "must be after start date")
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
      errors.add(field, "must be greater than or equal to 0")
    end
  end

  def generate_code
    loop do
      self.code = "BONUS_#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(code: code)
    end
  end

  def minimum_deposit_for_appropriate_types
    # minimum_deposit не должно быть установлено для событий, которые не требуют депозита
    non_deposit_events = %w[input_coupon manual collection groups_update scheduler]

    if non_deposit_events.include?(event) && minimum_deposit.present?
      errors.add(:minimum_deposit, "не должно быть установлено для события #{event}")
    end

    # Для депозитных событий minimum_deposit может использоваться как базовое требование
    if event == "deposit" && minimum_deposit.present?
      # Это теперь нормально - minimum_deposit может быть общим требованием
    end
  end
end
