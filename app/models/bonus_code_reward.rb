class BonusCodeReward < ApplicationRecord
  belongs_to :bonus

  # Serialize config as JSON for additional parameters
  serialize :config, coder: JSON

  validates :set_bonus_code, presence: true
  validates :title, presence: true

  # Config accessors for common parameters
  def config
    super || {}
  end

  # Helper methods
  def formatted_bonus_code
    set_bonus_code.present? ? set_bonus_code.upcase : "N/A"
  end

  def display_title
    title.present? ? title : "Бонус-код #{set_bonus_code}"
  end
end
