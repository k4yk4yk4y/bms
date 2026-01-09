module PermissionsCatalog
  PERMISSION_LEVELS = %w[none read write manage].freeze
  PERMISSION_LEVEL_LABELS = {
    "none" => "Нет",
    "read" => "Чтение",
    "write" => "Редактирование",
    "manage" => "Полный доступ"
  }.freeze

  FRONTEND_SECTIONS = [
    { key: "dashboard", label: "Dashboard" },
    { key: "bonuses", label: "Bonuses" },
    { key: "bonus_templates", label: "Bonus templates" },
    { key: "marketing_requests", label: "Marketing requests" },
    { key: "permanent_bonuses", label: "Permanent bonuses" },
    { key: "users", label: "Users" },
    { key: "retention", label: "Retention" },
    { key: "settings", label: "Settings" },
    { key: "api", label: "API" },
    { key: "self_profile", label: "Self profile" }
  ].freeze

  ADMIN_SECTIONS = [
    { key: "dashboard", label: "Dashboard" },
    { key: "bonuses", label: "Bonuses" },
    { key: "bonus_templates", label: "Bonus templates" },
    { key: "marketing_requests", label: "Marketing requests" },
    { key: "bonus_audit_logs", label: "Bonus audit logs" },
    { key: "dsl_tags", label: "DSL tags" },
    { key: "permanent_bonuses", label: "Permanent bonuses" },
    { key: "projects", label: "Projects" },
    { key: "users", label: "Users" },
    { key: "admin_users", label: "Admin users" },
    { key: "roles", label: "Roles" },
    { key: "admin_roles", label: "Admin roles" }
  ].freeze

  def self.section_keys(sections)
    sections.map { |section| section[:key] }
  end

  def self.normalize_permissions_hash(source, section_keys)
    normalized = {}
    section_keys.each do |section_key|
      level = source.to_h[section_key].to_s
      normalized[section_key] = PERMISSION_LEVELS.include?(level) ? level : "none"
    end
    normalized
  end
end
