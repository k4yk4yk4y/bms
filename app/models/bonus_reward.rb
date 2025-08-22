class BonusReward < ApplicationRecord
  include BonusCommonParameters

  belongs_to :bonus

  validates :reward_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :wager, numericality: { greater_than_or_equal_to: 0 }
  validates :max_win_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_win_type, inclusion: { in: %w[fixed multiplier] }, allow_nil: true

  scope :by_type, ->(type) { where(reward_type: type) }

  # Store additional configuration as JSON
  serialize :config, coder: JSON

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
    return "No limit" if max_win_value.blank?
    value = max_win_value.to_i == max_win_value ? max_win_value.to_i : max_win_value
    return "#{value}x" if max_win_type == 'multiplier'
    "#{value} #{bonus.currencies.first || ''}"
  end
end
