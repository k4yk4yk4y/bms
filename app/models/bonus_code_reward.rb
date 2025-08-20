class BonusCodeReward < ApplicationRecord
  include BonusCommonParameters

  belongs_to :bonus

  # Serialize config as JSON for additional parameters
  serialize :config, coder: JSON

  validates :code, presence: true
  validates :code_type, presence: true

  # Config accessors for common parameters
  def config
    super || {}
  end

  # Helper methods
  def formatted_bonus_code
    code.present? ? code.upcase : "N/A"
  end

  def title
    config["title"] || "Бонус-код #{code}"
  end

  def title=(value)
    self.config = (config || {}).merge("title" => value)
  end

  def display_title
    title
  end

  # For backward compatibility
  def set_bonus_code
    code
  end

  def set_bonus_code=(value)
    self.code = value
  end
end
