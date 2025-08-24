class BonusAuditLog < ApplicationRecord
  belongs_to :bonus
  belongs_to :user

  # Actions constants
  ACTIONS = %w[created updated deleted activated deactivated].freeze

  # Validations
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :bonus, presence: true
  validates :user, presence: true

  # Serialize JSON data
  serialize :changes_data, coder: JSON
  serialize :metadata, coder: JSON

  # Scopes
  scope :by_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # Instance methods
  def action_label
    case action
    when "created"
      "Создан"
    when "updated"
      "Обновлен"
    when "deleted"
      "Удален"
    when "activated"
      "Активирован"
    when "deactivated"
      "Деактивирован"
    else
      action.humanize
    end
  end

  def formatted_changes
    return "Нет изменений" if changes_data.blank?

    changes_data.map do |field, change|
      old_value = change[0]
      new_value = change[1]

      case field
      when "status"
        "Статус: #{old_value} → #{new_value}"
      when "name"
        "Название: #{old_value} → #{new_value}"
      when "code"
        "Код: #{old_value} → #{new_value}"
      when "event"
        "Событие: #{old_value} → #{new_value}"
      when "availability_start_date"
        "Дата начала: #{format_datetime(old_value)} → #{format_datetime(new_value)}"
      when "availability_end_date"
        "Дата окончания: #{format_datetime(old_value)} → #{format_datetime(new_value)}"
      when "currencies"
        "Валюты: #{format_array(old_value)} → #{format_array(new_value)}"
      when "currency_minimum_deposits"
        "Минимальные депозиты: #{format_hash(old_value)} → #{format_hash(new_value)}"
      else
        "#{field.humanize}: #{old_value} → #{new_value}"
      end
    end.join("\n")
  end

  def has_changes?
    changes_data.present? && changes_data.any?
  end

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "action", "bonus_id", "changes_data", "created_at", "id", "id_value", "metadata", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "bonus", "user" ]
  end

  private

  def format_datetime(value)
    return "не установлено" if value.blank?
    Time.parse(value).strftime("%d.%m.%Y %H:%M") rescue value.to_s
  end

  def format_array(value)
    return "не установлено" if value.blank?
    value.is_a?(Array) ? value.join(", ") : value.to_s
  end

  def format_hash(value)
    return "не установлено" if value.blank?
    value.is_a?(Hash) ? value.map { |k, v| "#{k}: #{v}" }.join(", ") : value.to_s
  end
end
