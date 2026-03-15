class BackfillRolesProjectsAndPermanentPermissions < ActiveRecord::Migration[8.0]
  class RoleRecord < ActiveRecord::Base
    self.table_name = "roles"
  end

  def up
    RoleRecord.reset_column_information

    RoleRecord.find_each do |role|
      permissions = role.permissions.to_h
      level = default_level_for(role.key)

      permissions["projects"] = "none" unless permissions.key?("projects")
      permissions["permanent_bonuses"] = "none" unless permissions.key?("permanent_bonuses")

      if level != "none"
        permissions["projects"] = level if permissions["projects"] == "none"
        permissions["permanent_bonuses"] = level if permissions["permanent_bonuses"] == "none"
      end

      role.update_columns(permissions: permissions)
    end
  end

  def down
    RoleRecord.find_each do |role|
      permissions = role.permissions.to_h
      next unless permissions.key?("projects") || permissions.key?("permanent_bonuses")

      permissions.delete("projects")
      permissions.delete("permanent_bonuses")
      role.update_columns(permissions: permissions)
    end
  end

  private

  def default_level_for(role_key)
    case role_key.to_s
    when "admin"
      "manage"
    when "promo_manager", "shift_leader", "retention_manager", "smm_manager", "delivery_manager", "support_agent"
      "read"
    else
      "none"
    end
  end
end
