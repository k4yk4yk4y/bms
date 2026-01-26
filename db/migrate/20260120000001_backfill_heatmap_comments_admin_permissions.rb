class BackfillHeatmapCommentsAdminPermissions < ActiveRecord::Migration[8.0]
  def up
    role_class = Class.new(ActiveRecord::Base) { self.table_name = "admin_roles" }
    role_class.reset_column_information

    superadmin = role_class.find_by(key: "superadmin")
    return unless superadmin

    permissions = superadmin.permissions.to_h
    permissions["heatmap_comments"] ||= "manage"
    superadmin.update_columns(permissions: permissions)
  end

  def down
    role_class = Class.new(ActiveRecord::Base) { self.table_name = "admin_roles" }
    role_class.reset_column_information

    superadmin = role_class.find_by(key: "superadmin")
    return unless superadmin

    permissions = superadmin.permissions.to_h
    permissions.delete("heatmap_comments")
    superadmin.update_columns(permissions: permissions)
  end
end
