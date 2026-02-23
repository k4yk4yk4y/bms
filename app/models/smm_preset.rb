class SmmPreset < ApplicationRecord
  include Auditable

  GROUPS = {
    "general" => "ОБЩИЕ",
    "chat_bonus" => "БОНУС ЧАТА",
    "game_channels" => "ИГРОВЫЕ КАНАЛЫ"
  }.freeze

  belongs_to :project
  belongs_to :manager, class_name: "User", optional: true

  has_many :smm_bonuses, dependent: :nullify

  attribute :currencies, :json, default: []

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :project_id, presence: true
  validates :bonus_type, presence: true
  validates :group, presence: true, inclusion: { in: GROUPS.keys }

  scope :ordered, -> { order(:name) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }

  def group_label
    GROUPS[group] || group
  end

  def currencies
    super || []
  end

  def currencies=(value)
    values = case value
             when String
               value.split(/[;,]/)
             when Array
               value
             else
               Array(value)
             end

    super(values.map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq)
  end
end
