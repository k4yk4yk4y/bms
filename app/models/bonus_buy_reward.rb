class BonusBuyReward < ApplicationRecord
  include BonusCommonParameters
  include CurrencyManagement

  belongs_to :bonus

  validates :buy_amount, presence: true, numericality: { greater_than: 0 }
  validates :multiplier, numericality: { greater_than: 0 }, allow_nil: true
  validates :bet_level, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :currency_bet_levels_must_be_present
  validate :validate_currency_bet_levels_precision

  # Store additional configuration as JSON
  serialize :config, coder: JSON
  serialize :games, coder: YAML

  # Common parameters accessors - DEPRECATED

  # Currency-specific bet levels
  def currency_bet_levels
    config&.dig("currency_bet_levels") || {}
  end

  def currency_bet_levels=(value)
    if value.is_a?(Hash)
      # Remove blank values and convert to proper format
      clean_value = value.reject { |_k, v| v.blank? }
      clean_value = clean_value.transform_values { |v| v.to_f }
      self.config = (config || {}).merge("currency_bet_levels" => clean_value)
    elsif value.blank?
      self.config = (config || {}).merge("currency_bet_levels" => {})
    else
      self.config = (config || {}).merge("currency_bet_levels" => value)
    end
  end

  def get_bet_level_for_currency(currency)
    currency_bet_levels[currency.to_s] || bet_level
  end

  def set_bet_level_for_currency(currency, value)
    levels = currency_bet_levels.dup
    levels[currency.to_s] = value&.to_f
    self.currency_bet_levels = levels
  end

  def formatted_currency_bet_levels
    return "No bet levels specified" if currency_bet_levels.empty?

    currency_bet_levels.map { |currency, amount| "#{currency}: #{amount}" }.join(", ")
  end

  def has_currency_bet_levels?
    currency_bet_levels.any?
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
      social_networks wager_done hold_min hold_max
    ]
  end

  def get_advanced_param(param)
    config&.dig(param)
  end

  def set_advanced_param(param, value)
    return unless advanced_params.include?(param)
    self.config = (config || {}).merge(param => value)
  end

  def formatted_buy_amount
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

  private

  def currency_bet_levels_must_be_present
    # Check if we have at least one currency with a non-zero bet level
    return if currency_bet_levels.present? &&
              currency_bet_levels.values.any? { |v| v.present? && v.to_f > 0 }

    errors.add(:currency_bet_levels, "a bet level must be provided for at least one currency")
  end

  def validate_currency_bet_levels_precision
    return unless currency_bet_levels.present?

    currency_bet_levels.each do |currency, amount|
      next if amount.blank?

      unless self.class.valid_amount_for_currency?(amount, currency)
        precision = self.class.currency_precision(currency)
        currency_type = self.class.crypto_currency?(currency) ? "cryptocurrency" : "fiat currency"
        errors.add(:currency_bet_levels,
          "for #{currency} (#{currency_type}) maximum #{precision} decimal places")
      end
    end
  end
end
