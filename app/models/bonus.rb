class Bonus < ApplicationRecord
  include CurrencyManagement
  include Auditable

  # Explicitly set table name
  self.table_name = "bonuses"

  # Status and type constants
  STATUSES = %w[draft active inactive expired].freeze
  EVENT_TYPES = %w[deposit input_coupon manual collection groups_update scheduler].freeze
  GROUPS = %w[VIP Platinum Gold Silver Bronze New Regular Premium Elite].freeze


  # New reward associations
  has_many :bonus_rewards, dependent: :destroy
  has_many :freespin_rewards, dependent: :destroy
  has_many :bonus_buy_rewards, dependent: :destroy
  has_many :comp_point_rewards, dependent: :destroy
  has_many :bonus_code_rewards, dependent: :destroy
  has_many :freechip_rewards, dependent: :destroy
  has_many :material_prize_rewards, dependent: :destroy

  # Audit associations
  has_many :bonus_audit_logs, dependent: :destroy
  belongs_to :creator, class_name: "User", foreign_key: "created_by", optional: true
  belongs_to :updater, class_name: "User", foreign_key: "updated_by", optional: true
  belongs_to :dsl_tag, optional: true


  # Store JSON data
  serialize :currencies, coder: JSON
  serialize :groups, coder: JSON
  serialize :currency_minimum_deposits, coder: JSON

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: false, length: { maximum: 50 }
  validates :event, presence: true, inclusion: { in: EVENT_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :availability_start_date, presence: true
  validates :availability_end_date, presence: true
  validates :maximum_winnings_type, presence: true, inclusion: { in: %w[fixed multiplier] }
  validates :dsl_tag, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }, allow_blank: true

  validate :end_date_after_start_date
  validate :valid_decimal_fields
  validate :validate_currency_minimum_deposits_precision
  validate :minimum_deposit_for_appropriate_types
  validate :valid_currency_minimum_deposits

  # Scopes
  scope :draft, -> { where(status: "draft") }
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :expired, -> { where(status: "expired") }
  scope :by_event, ->(event) { where(event: event) }
  scope :by_currency, ->(currency) { where("currencies::jsonb @> ?", [ currency ].to_json) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_project, ->(project) { where(project: project) }
  scope :by_dsl_tag, ->(dsl_tag) { 
    left_joins(:dsl_tag).where(
      "dsl_tags.name ILIKE ? OR bonuses.dsl_tag ILIKE ?", 
      "%#{dsl_tag}%", "%#{dsl_tag}%"
    )
  }
  scope :available_now, -> { where("availability_start_date <= ? AND availability_end_date >= ?", Time.current, Time.current) }

  scope :deposit_event, -> { where(event: "deposit") }
  scope :input_coupon_event, -> { where(event: "input_coupon") }
  scope :manual_event, -> { where(event: "manual") }
  scope :collection_event, -> { where(event: "collection") }
  scope :groups_update_event, -> { where(event: "groups_update") }
  scope :scheduler_event, -> { where(event: "scheduler") }

  # Callbacks
  before_validation :set_default_currencies, if: -> { currencies.blank? }
  before_validation :set_default_project, if: -> { project.blank? }
  after_find :check_and_update_expired_status!

  # Class method for groups
  def self.all_groups
    GROUPS
  end

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "availability_end_date", "availability_start_date", "code", "country", "created_at", "created_by", "currencies", "currency_minimum_deposits", "description", "dsl_tag", "event", "groups", "id", "id_value", "maximum_winnings", "maximum_winnings_type", "minimum_deposit", "name", "no_more", "project", "status", "tags", "totally_no_more", "updated_at", "updated_by", "user_group", "wager", "wagering_strategy" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "bonus_audit_logs", "creator", "updater" ]
  end

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
    types << "bonus" if bonus_rewards.any?
    types << "freespins" if freespin_rewards.any?
    types << "bonus_buy" if bonus_buy_rewards.any?
    types << "freechips" if freechip_rewards.any?
    types << "bonus_code" if bonus_code_rewards.any?
    types << "material_prize" if material_prize_rewards.any?
    types << "comp_point" if comp_point_rewards.any?
    types
  end

  # Methods to get data from rewards for display in table
  def display_code
    # Try to get code from first reward, fallback to bonus code
    first_reward = all_rewards.first
    first_reward&.code || code
  end

  def display_currency
    # Try to get currency from first reward, fallback to bonus currencies
    first_reward = all_rewards.first
    if first_reward&.respond_to?(:currencies) && first_reward.currencies.present?
      first_reward.currencies.is_a?(Array) ? first_reward.currencies.join(", ") : first_reward.currencies
    else
      currencies.present? ? currencies.join(", ") : "All currencies"
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
      first_reward.tags.is_a?(Array) ? first_reward.tags.join(", ") : first_reward.tags
    else
      tags
    end
  end

  def display_user_group
    # Try to get groups from first reward, fallback to bonus user_group
    first_reward = all_rewards.first
    if first_reward&.respond_to?(:groups) && first_reward.groups.present?
      first_reward.groups.is_a?(Array) ? first_reward.groups.join(", ") : first_reward.groups
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
      super(value.split(",").map(&:strip).reject(&:blank?))
    else
      super(value)
    end
  end

  def formatted_currencies
    currencies.join(", ") if currencies.any?
  end

  # Groups methods
  def groups
    super || []
  end

  def groups=(value)
    if value.is_a?(Array)
      super(value.reject(&:blank?))
    elsif value.is_a?(String)
      super(value.split(",").map(&:strip).reject(&:blank?))
    else
      super(value)
    end
  end

  def formatted_groups
    groups.join(", ") if groups.any?
  end

  # Currency minimum deposits methods
  def currency_minimum_deposits
    super || {}
  end

  def currency_minimum_deposits=(value)
    if value.is_a?(Hash)
      # Remove blank values and convert to proper format
      clean_value = value.reject { |_k, v| v.blank? }
      clean_value = clean_value.transform_values { |v| v.to_f }
      super(clean_value)
    elsif value.blank?
      super({})
    else
      super(value)
    end
  end

  def formatted_currency_minimum_deposits
    return "No minimum deposits specified" if currency_minimum_deposits.empty?

    # Handle case where currency_minimum_deposits is a string
    deposits = currency_minimum_deposits.is_a?(String) ? JSON.parse(currency_minimum_deposits) : currency_minimum_deposits
    return "No minimum deposits specified" unless deposits.is_a?(Hash) && deposits.any?

    deposits.map { |currency, amount| "#{currency}: #{amount}" }.join(", ")
  end

  def minimum_deposit_for_currency(currency)
    currency_minimum_deposits[currency.to_s]
  end

  def has_minimum_deposit_requirements?
    currency_minimum_deposits.any?
  end

  # Limitation methods
  def formatted_no_more
    no_more.present? ? no_more : "No limit"
  end

  def formatted_totally_no_more
    totally_no_more.present? ? "#{totally_no_more} total" : "Unlimited"
  end

  def formatted_maximum_winnings
    return "No limit" if maximum_winnings.blank?

    if maximum_winnings_type == "multiplier"
      "x#{maximum_winnings}"
    else
      "#{maximum_winnings} #{currencies.first || 'EUR'}"
    end
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

  def check_and_update_expired_status!
    return unless persisted? # Only check saved records

    # If bonus has expired and is still active, mark it as inactive
    if expired? && status == "active"
      update_column(:status, "inactive") # Use update_column to avoid callbacks loop
    end
  end

  # Class method to update all expired bonuses
  def self.update_expired_bonuses!
    active.where("availability_end_date < ?", Time.current)
          .update_all(status: "inactive")
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

  def validate_currency_minimum_deposits_precision
    return unless currency_minimum_deposits.present?

    # Handle case where currency_minimum_deposits is a string
    deposits = currency_minimum_deposits.is_a?(String) ? JSON.parse(currency_minimum_deposits) : currency_minimum_deposits
    return unless deposits.is_a?(Hash)

    deposits.each do |currency, amount|
      next if amount.nil?

      unless self.class.valid_amount_for_currency?(amount, currency)
        precision = self.class.currency_precision(currency)
        currency_type = self.class.crypto_currency?(currency) ? "криптовалюты" : "фиатной валюты"
        errors.add(:currency_minimum_deposits,
          "для #{currency} (#{currency_type}) максимум #{precision} знаков после запятой")
      end
    end
  end

  def set_default_currencies
    self.currencies = self.class.all_currencies
  end

  # Method removed - no longer needed as we only use currencies array

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

  def valid_currency_minimum_deposits
    return if currency_minimum_deposits.blank?

    # Handle case where currency_minimum_deposits is a string
    deposits = currency_minimum_deposits.is_a?(String) ? JSON.parse(currency_minimum_deposits) : currency_minimum_deposits
    return unless deposits.is_a?(Hash)

    # Проверяем, что currency_minimum_deposits не должно быть установлено для событий, которые не требуют депозита
    non_deposit_events = %w[input_coupon manual collection groups_update scheduler]

    if non_deposit_events.include?(event) && deposits.any?
      errors.add(:currency_minimum_deposits, "не должно быть установлено для события #{event}")
      return
    end

    # Проверяем, что все значения являются положительными числами
    deposits.each do |currency, amount|
      if amount.blank? || amount.to_f <= 0
        errors.add(:currency_minimum_deposits, "для валюты #{currency} должно быть положительным числом")
      end
    end

    # Проверяем, что указанные валюты есть в списке поддерживаемых валют
    if currencies.present?
      invalid_currencies = deposits.keys - currencies
      if invalid_currencies.any?
        errors.add(:currency_minimum_deposits, "содержит валюты, которые не указаны в списке поддерживаемых валют: #{invalid_currencies.join(', ')}")
      end
    end
  end

  # Audit methods
  def log_creation(user)
    return unless user

    bonus_audit_logs.create!(
      user: user,
      action: "created",
      changes_data: attributes.except("id", "created_at", "updated_at", "created_by", "updated_by"),
      metadata: { ip_address: Current.request&.remote_ip }
    )
  end

  def log_update(user, changes)
    return unless user && changes.any?

    bonus_audit_logs.create!(
      user: user,
      action: "updated",
      changes_data: changes,
      metadata: { ip_address: Current.request&.remote_ip }
    )
  end

  def log_status_change(user, old_status, new_status)
    return unless user && old_status != new_status

    bonus_audit_logs.create!(
      user: user,
      action: new_status == "active" ? "activated" : "deactivated",
      changes_data: { "status" => [ old_status, new_status ] },
      metadata: { ip_address: Current.request&.remote_ip }
    )
  end

  def log_deletion(user)
    return unless user

    bonus_audit_logs.create!(
      user: user,
      action: "deleted",
      changes_data: attributes.except("id", "created_at", "updated_at", "created_by", "updated_by"),
      metadata: { ip_address: Current.request&.remote_ip }
    )
  end

  # Helper methods for audit
  def creator_name
    creator&.full_name || creator&.email || "System"
  end

  def updater_name
    updater&.full_name || updater&.email || "System"
  end

  def set_default_project
    self.project = "All" if project.blank?
  end

  private
end
