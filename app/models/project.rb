class Project < ApplicationRecord
  has_many :permanent_bonuses, dependent: :destroy
  has_many :retention_chains, dependent: :nullify

  serialize :currencies, coder: JSON

  validates :name, presence: true, uniqueness: true
  validate :validate_currency_codes

  def self.ransackable_attributes(auth_object = nil)
    [ "name", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "permanent_bonuses" ]
  end

  def self.available_currencies
    Project.pluck(:currencies).flat_map do |value|
      case value
      when String
        JSON.parse(value)
      when Array
        value
      else
        []
      end
    rescue JSON::ParserError
      []
    end.compact.uniq
  end

  def self.currencies_by_project
    currencies_map = Project.order(:name).each_with_object({}) do |project, map|
      map[project.name] = project.currencies
    end
    currencies_map["All"] ||= available_currencies
    currencies_map
  end

  def currencies
    super || []
  end

  def currencies=(value)
    super(normalize_currency_codes(value))
  end

  def formatted_currencies
    currencies.join(", ") if currencies.any?
  end

  private

  def normalize_currency_codes(value)
    values = case value
             when String
               value.split(/[;,]/)
             when Array
               value
             else
               Array(value)
             end

    values.map { |code| code.to_s.strip.upcase }
          .reject(&:blank?)
          .uniq
  end

  def validate_currency_codes
    return if currencies.blank?

    invalid = currencies.reject { |code| code.match?(/\A[A-Z]{3,5}\z/) }
    return if invalid.empty?

    errors.add(:currencies, "contains invalid currency codes: #{invalid.join(', ')}")
  end
end
