class BonusReward < ApplicationRecord
  include BonusCommonParameters

  belongs_to :bonus

  validates :reward_type, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  validate :amount_percentage_or_currency_amounts_present
  validate :validate_currency_amounts


  scope :by_type, ->(type) { where(reward_type: type) }

  # Store additional configuration as JSON
  serialize :config, coder: JSON

  # Store currency amounts as JSON
  serialize :currency_amounts, coder: JSON

  # Common parameters accessors - DEPRECATED
  # These attributes have been moved to dedicated columns.
  # The accessor methods are left here for a transition period if needed,
  # but direct column access should be used.

  # Advanced parameters accessors
  def advanced_params
    @advanced_params ||= %w[
      range last_login_country profile_country current_ip_country emails stag
      deposit_payment_systems cashout_payment_systems user_can_have_disposable_email
      total_deposits deposits_sum loss_sum deposits_count spend_sum category_loss_sum
      wager_sum bets_count affiliates_user balance cashout chargeable_comp_points
      persistent_comp_points date_of_birth deposit gender issued_bonus registered
      social_networks hold_min hold_max
    ]
  end

  def get_advanced_param(param)
    config&.dig(param)
  end

  def set_advanced_param(param, value)
    return unless advanced_params.include?(param)
    self.config = (config || {}).merge(param => value)
  end

  def formatted_amount
    return "#{percentage}%" if percentage.present?
    "#{amount} #{bonus.currencies.first || ''}"
  end

  def formatted_max_win
    return "No limit" if bonus.maximum_winnings.blank?

    if bonus.maximum_winnings_type == "multiplier"
      value = bonus.maximum_winnings.to_i == bonus.maximum_winnings ? bonus.maximum_winnings.to_i : bonus.maximum_winnings
      "#{value}x"
    else
      value = bonus.maximum_winnings.to_i == bonus.maximum_winnings ? bonus.maximum_winnings.to_i : bonus.maximum_winnings
      "#{value} #{bonus.currencies.first || ''}"
    end
  end

  # Добавляем недостающие методы для совместимости с тестами
  def max_win_value
    bonus&.maximum_winnings
  end

  def max_win_value=(value)
    return unless bonus
    bonus.maximum_winnings = value
  end

  def max_win_type
    bonus&.maximum_winnings_type
  end

  def max_win_type=(value)
    return unless bonus
    bonus.maximum_winnings_type = value
  end

  def available
    config&.dig("available")
  end

  def available=(value)
    self.config = (config || {}).merge("available" => value)
  end

  # Currency amounts handling
  def has_currency_amounts?
    currency_amounts.present? && currency_amounts.any?
  end

  def formatted_currency_amounts
    return "No amounts set" if currency_amounts.blank?
    currency_amounts.map { |currency, amount| "#{currency}: #{amount}" }.join(", ")
  end

  # Include CurrencyManagement for validation methods
  include CurrencyManagement

  # Validation for currency amounts
  def validate_currency_amounts
    return if currency_amounts.blank?

    currency_amounts.each do |currency, amount|
      next if amount.blank?

      unless self.class.valid_amount_for_currency?(amount, currency)
        errors.add(:currency_amounts, "Invalid amount for currency #{currency}: #{amount}")
      end
    end
  end

  private

  def amount_percentage_or_currency_amounts_present
    return if amount.present? || percentage.present?
    return if currency_amounts.present? && currency_amounts.values.any? { |value| value.present? }

    errors.add(:base, "Нужно указать сумму, процент или суммы по валютам")
  end
end
