class BonusBuyReward < ApplicationRecord
  include BonusCommonParameters
  include CurrencyManagement

  belongs_to :bonus

  validates :buy_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :multiplier, numericality: { greater_than: 0 }, allow_nil: true
  validates :bet_level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validate :currency_buy_amounts_must_be_present
  validate :validate_currency_buy_amounts_precision

  # Store additional configuration as JSON
  serialize :config, coder: JSON
  serialize :games, coder: YAML

  # Common parameters accessors - DEPRECATED

  # Currency-specific purchase amounts
  def currency_buy_amounts
    values = config&.dig("currency_buy_amounts")
    return values if values.present?

    # Backward compatibility for records that still store old key.
    config&.dig("currency_bet_levels") || {}
  end

  def currency_buy_amounts=(value)
    clean_value = normalize_currency_values(value)
    new_config = (config || {}).merge("currency_buy_amounts" => clean_value)
    new_config.delete("currency_bet_levels")
    self.config = new_config
  end

  # Backward compatibility aliases for old field naming.
  def currency_bet_levels
    currency_buy_amounts
  end

  def currency_bet_levels=(value)
    self.currency_buy_amounts = value
  end

  def get_buy_amount_for_currency(currency)
    currency_buy_amounts[currency.to_s]
  end

  def set_buy_amount_for_currency(currency, value)
    amounts = currency_buy_amounts.dup
    amounts[currency.to_s] = value&.to_f
    self.currency_buy_amounts = amounts
  end

  def get_bet_level_for_currency(currency)
    currency_buy_amounts[currency.to_s] || bet_level
  end

  def set_bet_level_for_currency(currency, value)
    levels = currency_buy_amounts.dup
    levels[currency.to_s] = value&.to_f
    self.currency_buy_amounts = levels
  end

  def formatted_currency_buy_amounts
    return "No purchase amounts specified" if currency_buy_amounts.empty?

    currency_buy_amounts.map { |currency, amount| "#{currency}: #{amount}" }.join(", ")
  end

  def formatted_currency_bet_levels
    formatted_currency_buy_amounts
  end

  def has_currency_buy_amounts?
    currency_buy_amounts.any?
  end

  def has_currency_bet_levels?
    has_currency_buy_amounts?
  end

  # Advanced parameters accessors
  def advanced_params
    @advanced_params ||= %w[
      auto_activate duration activation_duration email_template range last_login_country
      profile_country current_ip_country emails stag deposit_payment_systems
      cashout_payment_systems user_can_have_duplicates user_can_have_disposable_email
      total_deposits deposits_sum loss_sum deposits_count spend_sum category_loss_sum
      wager_sum bets_count affiliates_user balance chargeable_comp_points
      persistent_comp_points date_of_birth deposit gender issued_bonus registered
      social_networks wager_done hold_min hold_max deposit_percentage
    ]
  end

  def get_advanced_param(param)
    config&.dig(param)
  end

  def set_advanced_param(param, value)
    return unless advanced_params.include?(param)
    self.config = (config || {}).merge(param => value)
  end

  def deposit_percentage
    config&.dig("deposit_percentage")
  end

  def deposit_percentage=(value)
    new_config = (config || {}).dup
    if value.blank?
      new_config.delete("deposit_percentage")
    else
      new_config["deposit_percentage"] = value.to_f
    end
    self.config = new_config
  end

  def formatted_buy_amount
    return formatted_currency_buy_amounts if currency_buy_amounts.any?

    "#{buy_amount} #{bonus.currencies.first || ''}"
  end

  def formatted_multiplier
    multiplier.present? ? "#{multiplier}x" : "N/A"
  end

  def has_game_restrictions?
    games.any?
  end

  def formatted_games
    games.join(", ") if games.any?
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

  def bonus_amount_for_currency(currency)
    amounts = currency_buy_amounts
    if amounts.present?
      return 0 unless amounts.key?(currency.to_s)

      amount = amounts[currency.to_s]
      return 0 if amount.blank?

      return amount.to_f
    end

    # Backward compatibility for older records.
    return buy_amount.to_f if buy_amount.present?
    return nil if bet_level.blank?

    return bet_level.to_f * multiplier.to_f if multiplier.present?

    bet_level.to_f
  end

  def minimum_deposit_amount_for_currency(currency)
    return nil if deposit_percentage.blank?

    bonus_amount = bonus_amount_for_currency(currency)
    return nil if bonus_amount.nil?

    bonus_amount * (deposit_percentage.to_f / 100.0)
  end

  private

  def currency_buy_amounts_must_be_present
    return if currency_buy_amounts.present? &&
              currency_buy_amounts.values.any? { |v| v.present? && v.to_f > 0 }

    # Keep old single amount as fallback for legacy records.
    return if buy_amount.present? && buy_amount.to_f > 0

    errors.add(:currency_buy_amounts, "a purchase amount must be provided for at least one currency")
  end

  def validate_currency_buy_amounts_precision
    return unless currency_buy_amounts.present?

    currency_buy_amounts.each do |currency, amount|
      next if amount.blank?

      unless self.class.valid_amount_for_currency?(amount, currency)
        precision = self.class.currency_precision(currency)
        currency_type = self.class.crypto_currency?(currency) ? "cryptocurrency" : "fiat currency"
        errors.add(:currency_buy_amounts,
          "for #{currency} (#{currency_type}) maximum #{precision} decimal places")
      end
    end
  end

  def normalize_currency_values(value)
    return {} if value.blank?

    if value.is_a?(Hash)
      value.each_with_object({}) do |(currency, amount), result|
        next if amount.blank?
        result[currency.to_s] = amount.to_f
      end
    else
      {}
    end
  end
end
