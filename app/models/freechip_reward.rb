class FreechipReward < ApplicationRecord
  include BonusCommonParameters

  belongs_to :bonus

  validates :chip_value, presence: true, numericality: { greater_than: 0 }
  validates :chips_count, presence: true, numericality: { greater_than: 0 }

  def total_value
    chip_value * chips_count
  end

  def formatted_chip_value
    "#{chip_value} #{bonus.currency}"
  end

  def formatted_total_value
    "#{total_value} #{bonus.currency}"
  end
end
