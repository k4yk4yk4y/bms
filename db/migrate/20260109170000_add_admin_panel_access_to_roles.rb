class AddAdminPanelAccessToRoles < ActiveRecord::Migration[8.0]
  def up
    add_column :roles, :admin_panel_access, :boolean, null: false, default: false

    role_class = Class.new(ActiveRecord::Base) { self.table_name = "roles" }
    role_class.reset_column_information
    role_class.where(key: "admin").update_all(admin_panel_access: true)
  end

  def down
    remove_column :roles, :admin_panel_access
  end
end
