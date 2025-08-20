class MaterialPrizeReward < ApplicationRecord
  include BonusCommonParameters
  
  belongs_to :bonus

  validates :prize_name, presence: true
  validates :prize_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def formatted_prize_value
    return "N/A" if prize_value.blank?
    "#{prize_value} #{bonus.currency}"
  end

  def has_monetary_value?
    prize_value.present? && prize_value > 0
  end
end
