class BonusReward < ApplicationRecord
  include BonusCommonParameters
  
  belongs_to :bonus

  validates :reward_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  scope :by_type, ->(type) { where(reward_type: type) }

  # Store additional configuration as JSON
  serialize :config, coder: JSON

  # Common parameters accessors
  def wager
    config&.dig("wager")
  end

  def wager=(value)
    self.config = (config || {}).merge("wager" => value&.to_f)
  end

  def max_win
    config&.dig("max_win")
  end

  def max_win=(value)
    self.config = (config || {}).merge("max_win" => value)
  end

  def max_win_type
    return "multiplier" if max_win.to_s.include?("x")
    "fixed"
  end

  def available
    config&.dig("available")
  end

  def available=(value)
    self.config = (config || {}).merge("available" => value&.to_i)
  end

  def code
    config&.dig("code")
  end

  def code=(value)
    self.config = (config || {}).merge("code" => value)
  end



  def user_can_have_duplicates
    config&.dig("user_can_have_duplicates") || false
  end

  def user_can_have_duplicates=(value)
    self.config = (config || {}).merge("user_can_have_duplicates" => [ true, "true", "1", 1 ].include?(value))
  end



  def stag
    config&.dig("stag")
  end

  def stag=(value)
    self.config = (config || {}).merge("stag" => value)
  end



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
    "#{amount} #{bonus.currency}"
  end

  def formatted_max_win
    return "No limit" if max_win.blank?
    return max_win if max_win.to_s.include?("x")
    "#{max_win} #{bonus.currency}"
  end


end
