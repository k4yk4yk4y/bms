class FreespinReward < ApplicationRecord
  belongs_to :bonus

  validates :spins_count, presence: true, numericality: { greater_than: 0 }

  # Store additional configuration as JSON
  serialize :config, coder: JSON

  # Common parameters accessors
  def games
    config&.dig('games') || []
  end

  def games=(value)
    games_array = value.is_a?(Array) ? value : value.to_s.split(',').map(&:strip).reject(&:blank?)
    self.config = (config || {}).merge('games' => games_array)
  end

  def bet_level
    config&.dig('bet_level')
  end

  def bet_level=(value)
    self.config = (config || {}).merge('bet_level' => value&.to_f)
  end

  def max_win
    config&.dig('max_win')
  end

  def max_win=(value)
    self.config = (config || {}).merge('max_win' => value)
  end

  def max_win_type
    return 'multiplier' if max_win.to_s.include?('x')
    'fixed'
  end

  def no_more
    config&.dig('no_more')
  end

  def no_more=(value)
    self.config = (config || {}).merge('no_more' => value)
  end

  def available
    config&.dig('available')
  end

  def available=(value)
    self.config = (config || {}).merge('available' => value&.to_i)
  end

  def code
    config&.dig('code')
  end

  def code=(value)
    self.config = (config || {}).merge('code' => value)
  end

  def currencies
    config&.dig('currencies') || []
  end

  def currencies=(value)
    currencies_array = value.is_a?(Array) ? value : [value].compact
    self.config = (config || {}).merge('currencies' => currencies_array)
  end

  def min_deposit
    config&.dig('min')
  end

  def min_deposit=(value)
    self.config = (config || {}).merge('min' => value&.to_f)
  end

  def groups
    config&.dig('groups') || []
  end

  def groups=(value)
    groups_array = value.is_a?(Array) ? value : value.to_s.split(',').map(&:strip).reject(&:blank?)
    self.config = (config || {}).merge('groups' => groups_array)
  end

  def tags
    config&.dig('tags') || []
  end

  def tags=(value)
    tags_array = value.is_a?(Array) ? value : value.to_s.split(',').map(&:strip).reject(&:blank?)
    self.config = (config || {}).merge('tags' => tags_array)
  end

  def stag
    config&.dig('stag')
  end

  def stag=(value)
    self.config = (config || {}).merge('stag' => value)
  end

  def wagering_strategy
    config&.dig('wagering_strategy')
  end

  def wagering_strategy=(value)
    self.config = (config || {}).merge('wagering_strategy' => value)
  end

  def totally_no_more
    config&.dig('totally_no_more')
  end

  def totally_no_more=(value)
    self.config = (config || {}).merge('totally_no_more' => value)
  end

  # Currency-specific bet levels
  def currency_bet_levels
    config&.dig('currency_bet_levels') || {}
  end

  def currency_bet_levels=(value)
    self.config = (config || {}).merge('currency_bet_levels' => value)
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
    game_restrictions.present? || games.any?
  end

  def formatted_games
    games.join(', ') if games.any?
  end

  def formatted_max_win
    return 'No limit' if max_win.blank?
    return max_win if max_win.to_s.include?('x')
    "#{max_win} #{bonus.currency}"
  end

  def formatted_groups
    groups.join(', ') if groups.any?
  end

  def formatted_tags
    tags.join(', ') if tags.any?
  end

  def formatted_currencies
    currencies.join(', ') if currencies.any?
  end
end
