class BonusTemplate < ApplicationRecord
  # Status and type constants
  EVENT_TYPES = %w[deposit input_coupon manual collection groups_update scheduler].freeze
  PROJECTS = %w[All VOLNA ROX FRESH SOL JET IZZI LEGZO STARDA DRIP MONRO 1GO LEX GIZBO IRWIN FLAGMAN MARTIN P17 ANJUAN NAMASTE].freeze

  # Store JSON data
  serialize :currencies, coder: JSON
  serialize :groups, coder: JSON
  serialize :currency_minimum_deposits, coder: JSON

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :dsl_tag, presence: true, length: { maximum: 255 }
  validates :project, presence: true, inclusion: { in: PROJECTS }
  validates :event, presence: true, inclusion: { in: EVENT_TYPES }
  # Currency validation removed - now using currencies array
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :dsl_tag, uniqueness: { scope: [ :project, :name ], message: "комбинация dsl_tag, project и name должна быть уникальной" }

  validate :valid_decimal_fields
  # minimum_deposit validation removed
  validate :valid_currency_minimum_deposits

  # Scopes
  scope :by_dsl_tag, ->(dsl_tag) { where(dsl_tag: dsl_tag) }
  scope :by_project, ->(project) { where(project: project) }
  scope :by_event, ->(event) { where(event: event) }
  scope :by_currency, ->(currency) { where("currencies::jsonb @> ?", [ currency ].to_json) }
  scope :for_all_projects, -> { where(project: "All") }
  scope :for_specific_project, ->(project) { where(project: project) }

  # Class methods
  def self.find_template(dsl_tag, project, name)
    where(dsl_tag: dsl_tag, project: project, name: name).first
  end

  # New method to find template by dsl_tag and name with project priority
  def self.find_template_by_dsl_and_name(dsl_tag, name, project = nil)
    # First try to find template for specific project
    if project.present?
      specific_template = where(dsl_tag: dsl_tag, name: name, project: project).first
      return specific_template if specific_template.present?
    end

    # If not found or no project specified, try to find "All" template
    where(dsl_tag: dsl_tag, name: name, project: "All").first
  end

  def self.templates_for_project(project)
    # Get specific project templates first, then "All" templates
    specific_templates = where(project: project).order(:dsl_tag, :name)
    all_templates = where(project: "All").order(:dsl_tag, :name)

    # Combine and remove duplicates (specific project templates take priority)
    specific_dsl_names = specific_templates.pluck(:dsl_tag, :name)
    filtered_all_templates = all_templates.reject do |template|
      specific_dsl_names.include?([ template.dsl_tag, template.name ])
    end

    specific_templates + filtered_all_templates
  end

  # Instance methods
  def apply_to_bonus(bonus)
    bonus.assign_attributes(
                                  dsl_tag: dsl_tag,
              project: project == "All" ? bonus.project : project,
              event: event,
              wager: wager,
              maximum_winnings: maximum_winnings,
              no_more: no_more,
              totally_no_more: totally_no_more,
              currencies: currencies,
              groups: groups,
              currency_minimum_deposits: currency_minimum_deposits,
              description: description
    )
  end

  # Check if template is for all projects
  def for_all_projects?
    project == "All"
  end

  # Check if template is for specific project
  def for_specific_project?
    project != "All"
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

    currency_minimum_deposits.map { |currency, amount| "#{currency}: #{amount}" }.join(", ")
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

  private

  def valid_decimal_fields
    # minimum_deposit validation removed
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

  # minimum_deposit validation method removed

  def valid_currency_minimum_deposits
    return if currency_minimum_deposits.blank?

    # Проверяем, что currency_minimum_deposits не должно быть установлено для событий, которые не требуют депозита
    non_deposit_events = %w[input_coupon manual collection groups_update scheduler]

    if non_deposit_events.include?(event) && currency_minimum_deposits.any?
      errors.add(:currency_minimum_deposits, "не должно быть установлено для события #{event}")
      return
    end

    # Проверяем, что все значения являются положительными числами
    currency_minimum_deposits.each do |currency, amount|
      if amount.blank? || amount.to_f <= 0
        errors.add(:currency_minimum_deposits, "для валюты #{currency} должно быть положительным числом")
      end
    end

    # Проверяем, что указанные валюты есть в списке поддерживаемых валют
    if currencies.present?
      invalid_currencies = currency_minimum_deposits.keys - currencies
      if invalid_currencies.any?
        errors.add(:currency_minimum_deposits, "содержит валюты, которые не указаны в списке поддерживаемых валют: #{invalid_currencies.join(', ')}")
      end
    end
  end
end
