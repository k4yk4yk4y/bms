class CreateAdminRoles < ActiveRecord::Migration[8.0]
  def up
    create_table :admin_roles do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.jsonb :permissions, null: false, default: {}

      t.timestamps
    end

    add_index :admin_roles, :key, unique: true

    add_reference :admin_users, :admin_role, foreign_key: true

    create_default_admin_roles
    assign_existing_admin_users

    change_column_null :admin_users, :admin_role_id, false
  end

  def down
    remove_reference :admin_users, :admin_role, foreign_key: true
    drop_table :admin_roles
  end

  private

  def create_default_admin_roles
    role_class = Class.new(ActiveRecord::Base) { self.table_name = "admin_roles" }
    role_class.reset_column_information

    role_class.create!(
      key: "superadmin",
      name: "Superadmin",
      permissions: admin_permissions_for(:manage)
    )

    role_class.create!(
      key: "read_only",
      name: "Read only",
      permissions: admin_permissions_for(:read)
    )
  end

  def assign_existing_admin_users
    admin_user_class = Class.new(ActiveRecord::Base) { self.table_name = "admin_users" }
    role_class = Class.new(ActiveRecord::Base) { self.table_name = "admin_roles" }

    superadmin_id = role_class.find_by(key: "superadmin")&.id
    return unless superadmin_id

    admin_user_class.update_all(admin_role_id: superadmin_id)
  end

  def admin_permissions_for(level)
    sections = %w[
      dashboard
      bonuses
      bonus_templates
      marketing_requests
      bonus_audit_logs
      dsl_tags
      permanent_bonuses
      projects
      users
      admin_users
      roles
      admin_roles
    ]

    sections.each_with_object({}) do |section, memo|
      memo[section] = level.to_s
    end
  end
end
