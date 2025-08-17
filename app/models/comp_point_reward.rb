class CompPointReward < ApplicationRecord
  belongs_to :bonus

  # Serialize config as JSON for additional parameters
  serialize :config, coder: JSON

  validates :points_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :multiplier, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Config accessors for common parameters
  def config
    super || {}
  end

  # Helper methods
  def formatted_points_amount
    points_amount.present? ? "#{points_amount} очков" : "0"
  end

  def formatted_multiplier
    multiplier.present? ? "×#{multiplier}" : "N/A"
  end

  def title
    config['title'] || "#{points_amount} comp points"
  end

  def title=(value)
    self.config = (config || {}).merge('title' => value)
  end

  def total_value
    return points_amount unless multiplier.present?
    points_amount * multiplier
  end
end
