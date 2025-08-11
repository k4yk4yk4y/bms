class DepositBonus < ApplicationRecord
  # Explicitly set table name
  self.table_name = 'deposit_bonuses'
  
  # Associations
  belongs_to :bonus

  # Validations
  validates :deposit_amount_required, presence: true, numericality: { greater_than: 0 }
  validates :bonus_percentage, presence: true, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 1000 
  }
  validates :max_bonus_amount, numericality: { greater_than: 0 }, allow_blank: true

  # Callbacks
  after_initialize :set_defaults

  # Instance methods
  def calculate_bonus_amount(deposit_amount)
    return 0 if deposit_amount < deposit_amount_required
    
    bonus_amount = deposit_amount * (bonus_percentage / 100)
    
    if max_bonus_amount.present?
      [bonus_amount, max_bonus_amount].min
    else
      bonus_amount
    end
  end

  def eligible_for_deposit?(deposit_amount, is_first_deposit = false)
    return false if deposit_amount < deposit_amount_required
    return false if first_deposit_only && !is_first_deposit
    
    true
  end

  def percentage_display
    "#{bonus_percentage}%"
  end

  private

  def set_defaults
    self.first_deposit_only ||= false
    self.recurring_eligible ||= false
  end
end
