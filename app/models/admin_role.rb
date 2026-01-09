class AdminRole < ApplicationRecord
  PERMISSION_LEVELS = PermissionsCatalog::PERMISSION_LEVELS
  PERMISSION_LEVEL_LABELS = PermissionsCatalog::PERMISSION_LEVEL_LABELS

  SECTION_DEFINITIONS = PermissionsCatalog::ADMIN_SECTIONS
  SECTION_HINTS = {
    "admin_users" => "Управление учетными записями администраторов.",
    "roles" => "Управление ролями пользователей фронта.",
    "users" => "Просмотр пользователей фронта из ActiveAdmin.",
    "admin_roles" => "Управление ролями администраторов."
  }.freeze

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
    PermissionsCatalog.section_keys(SECTION_DEFINITIONS)
  end

  def self.permission_level_options
    PERMISSION_LEVEL_LABELS.map { |value, label| [ label, value ] }
  end

  def self.section_label(key)
    SECTION_DEFINITIONS.find { |section| section[:key] == key.to_s }&.fetch(:label, key.to_s.humanize) || key.to_s.humanize
  end

  def self.section_hint(key)
    SECTION_HINTS[key.to_s]
  end

  def self.normalize_permissions_hash(source)
    PermissionsCatalog.normalize_permissions_hash(source, section_keys)
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
