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
end
