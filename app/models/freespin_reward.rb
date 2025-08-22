class FreespinReward < ApplicationRecord
  include BonusCommonParameters

  belongs_to :bonus

  validates :spins_count, presence: true, numericality: { greater_than: 0 }
  validates :bet_level, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_win_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_win_type, inclusion: { in: %w[fixed multiplier] }, allow_nil: true
  validate :currency_freespin_bet_levels_must_be_present

  # Store additional configuration as JSON
  serialize :config, coder: JSON
  serialize :games, coder: YAML

  # Common parameters accessors - DEPRECATED

  # Currency-specific bet levels
  def currency_bet_levels
    config&.dig("currency_bet_levels") || {}
  end

  def currency_bet_levels=(value)
    self.config = (config || {}).merge("currency_bet_levels" => value)
  end

  def get_bet_level_for_currency(currency)
    currency_bet_levels[currency.to_s] || bet_level
  end

  def set_bet_level_for_currency(currency, value)
    levels = currency_bet_levels.dup
    levels[currency.to_s] = value&.to_f
    self.currency_bet_levels = levels
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

  def formatted_spins
    "#{spins_count} #{'spin'.pluralize(spins_count)}"
  end

  def has_game_restrictions?
    games.any?
  end

  def formatted_games
    games.join(", ") if games.any?
  end

  def formatted_max_win
    return "No limit" if max_win_value.blank?
    value = max_win_value.to_i == max_win_value ? max_win_value.to_i : max_win_value
    return "#{value}x" if max_win_type == "multiplier"
    "#{value} #{bonus.currencies.first || ''}"
  end

  # Currency-specific freespin bet levels (required field)
  def currency_freespin_bet_levels
    config&.dig("currency_freespin_bet_levels") || {}
  end

  def currency_freespin_bet_levels=(value)
    if value.is_a?(Hash)
      # Remove blank values and convert to proper format
      clean_value = value.reject { |_k, v| v.blank? }
      clean_value = clean_value.transform_values { |v| v.to_f }
      self.config = (config || {}).merge("currency_freespin_bet_levels" => clean_value)
    elsif value.blank?
      self.config = (config || {}).merge("currency_freespin_bet_levels" => {})
    else
      self.config = (config || {}).merge("currency_freespin_bet_levels" => value)
    end
  end

  def formatted_currency_freespin_bet_levels
    return "No bet levels specified" if currency_freespin_bet_levels.empty?

    currency_freespin_bet_levels.map { |currency, amount| "#{currency}: #{amount}" }.join(", ")
  end

  def get_freespin_bet_level_for_currency(currency)
    currency_freespin_bet_levels[currency.to_s] || bet_level
  end

  def set_freespin_bet_level_for_currency(currency, value)
    levels = currency_freespin_bet_levels.dup
    levels[currency.to_s] = value&.to_f
    self.currency_freespin_bet_levels = levels
  end

  def has_currency_freespin_bet_levels?
    currency_freespin_bet_levels.any?
  end

  private

  def currency_freespin_bet_levels_must_be_present
    # Check if we have at least one currency with a non-zero bet level
    return if currency_freespin_bet_levels.present? &&
              currency_freespin_bet_levels.values.any? { |v| v.present? && v.to_f > 0 }

    errors.add(:currency_freespin_bet_levels, "должен быть указан размер ставки фриспинов хотя бы для одной валюты")
  end
end
