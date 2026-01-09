class Role < ApplicationRecord
  PERMISSION_LEVELS = %w[none read manage].freeze
  PERMISSION_LEVEL_LABELS = {
    "none" => "Нет",
    "read" => "Чтение",
    "manage" => "Полный доступ"
  }.freeze

  SECTION_DEFINITIONS = [
    { key: "dashboard", label: "Dashboard" },
    { key: "bonuses", label: "Bonuses" },
    { key: "bonus_templates", label: "Bonus templates" },
    { key: "marketing_requests", label: "Marketing requests" },
    { key: "permanent_bonuses", label: "Permanent bonuses" },
    { key: "users", label: "Users" },
    { key: "retention", label: "Retention" }
  ].freeze

  SECTION_DEFINITIONS.each do |section|
    define_method(section[:key]) do
      permission_level_for(section[:key])
    end
  end

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validate :validate_permissions

  before_validation :normalize_permissions

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "key", "name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.section_keys
    SECTION_DEFINITIONS.map { |section| section[:key] }
  end

  def self.permission_level_options
    PERMISSION_LEVEL_LABELS.map { |value, label| [ label, value ] }
  end

  def self.section_label(key)
    SECTION_DEFINITIONS.find { |section| section[:key] == key.to_s }&.fetch(:label, key.to_s.humanize) || key.to_s.humanize
  end

  def self.default_permissions_for(role_key)
    defaults = DEFAULT_PERMISSIONS.fetch(role_key.to_s, {})
    normalize_permissions_hash(defaults)
  end

  def self.permissions_for(role_key)
    role = find_by(key: role_key.to_s)
    role ? normalize_permissions_hash(role.permissions) : default_permissions_for(role_key)
  end

  def self.normalize_permissions_hash(source)
    normalized = {}
    section_keys.each do |section_key|
      level = source.to_h[section_key].to_s
      normalized[section_key] = PERMISSION_LEVELS.include?(level) ? level : "none"
    end
    normalized
  end

  def permission_level_for(section_key)
    permissions.to_h[section_key.to_s] || "none"
  end

  def permissions_summary
    permissions.to_h.filter_map do |section_key, level|
      next if level == "none"

      "#{self.class.section_label(section_key)}: #{PERMISSION_LEVEL_LABELS[level] || level}"
    end.join(", ")
  end

  private

  DEFAULT_PERMISSIONS = {
    "admin" => {
      "dashboard" => "manage",
      "bonuses" => "manage",
      "bonus_templates" => "manage",
      "marketing_requests" => "manage",
      "permanent_bonuses" => "manage",
      "users" => "read",
      "retention" => "manage"
    },
    "promo_manager" => {
      "dashboard" => "read",
      "bonuses" => "read",
      "users" => "read",
      "retention" => "read"
    },
    "shift_leader" => {
      "dashboard" => "read",
      "bonuses" => "read",
      "marketing_requests" => "read",
      "users" => "read",
      "retention" => "read"
    },
    "marketing_manager" => {
      "dashboard" => "read",
      "marketing_requests" => "manage",
      "users" => "read"
    },
    "retention_manager" => {
      "dashboard" => "read",
      "bonuses" => "read",
      "users" => "read",
      "retention" => "manage"
    },
    "support_agent" => {
      "dashboard" => "read",
      "bonuses" => "read",
      "marketing_requests" => "read",
      "users" => "read",
      "retention" => "read"
    }
  }.freeze

  def normalize_permissions
    self.permissions = self.class.normalize_permissions_hash(permissions || {})
  end

  def validate_permissions
    permissions.to_h.each do |section_key, level|
      next if self.class.section_keys.include?(section_key.to_s)

      errors.add(:permissions, "Недопустимый раздел: #{section_key}")
    end

    permissions.to_h.each do |section_key, level|
      next if self.class::PERMISSION_LEVELS.include?(level.to_s)

      errors.add(:permissions, "Недопустимый уровень доступа для #{section_key}")
    end
  end
end
