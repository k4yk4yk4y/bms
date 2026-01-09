class CreateRoles < ActiveRecord::Migration[8.0]
  def up
    create_table :roles do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.jsonb :permissions, null: false, default: {}

      t.timestamps
    end

    add_index :roles, :key, unique: true

    create_default_roles
  end

  def down
    drop_table :roles
  end

  private

  def create_default_roles
    role_class = Class.new(ActiveRecord::Base) { self.table_name = "roles" }
    role_class.reset_column_information

    default_permissions = {
      "admin" => permissions_for(:manage),
      "promo_manager" => permissions_for(:read).merge(
        "marketing_requests" => "none",
        "bonus_templates" => "none",
        "settings" => "none",
        "api" => "none",
        "users" => "none",
        "admin_users" => "none",
        "bonus_audit_logs" => "none",
        "dsl_tags" => "none",
        "permanent_bonuses" => "none",
        "projects" => "none"
      ),
      "shift_leader" => permissions_for(:read).merge(
        "bonus_templates" => "none",
        "settings" => "none",
        "api" => "none",
        "users" => "none",
        "admin_users" => "none",
        "bonus_audit_logs" => "none",
        "dsl_tags" => "none",
        "permanent_bonuses" => "none",
        "projects" => "none"
      ),
      "marketing_manager" => permissions_for(:none).merge(
        "dashboard" => "read",
        "marketing_requests" => "manage",
        "users" => "read"
      ),
      "retention_manager" => permissions_for(:none).merge(
        "dashboard" => "read",
        "bonuses" => "read",
        "retention" => "manage"
      ),
      "support_agent" => permissions_for(:read).merge(
        "bonus_templates" => "none",
        "settings" => "none",
        "api" => "none",
        "users" => "none",
        "admin_users" => "none",
        "bonus_audit_logs" => "none",
        "dsl_tags" => "none",
        "permanent_bonuses" => "none",
        "projects" => "none"
      )
    }

    default_permissions.each do |key, permissions|
      role_class.create!(
        key: key,
        name: key.tr("_", " ").split.map(&:capitalize).join(" "),
        permissions: permissions
      )
    end
  end

  def permissions_for(level)
    {
      "dashboard" => level.to_s,
      "bonuses" => level.to_s,
      "bonus_templates" => level.to_s,
      "marketing_requests" => level.to_s,
      "bonus_audit_logs" => level.to_s,
      "dsl_tags" => level.to_s,
      "permanent_bonuses" => level.to_s,
      "projects" => level.to_s,
      "users" => level.to_s,
      "admin_users" => level.to_s,
      "retention" => level.to_s,
      "settings" => level.to_s,
      "api" => level.to_s
    }
  end
end
