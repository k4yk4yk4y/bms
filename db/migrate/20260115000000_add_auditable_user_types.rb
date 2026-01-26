class AddAuditableUserTypes < ActiveRecord::Migration[8.0]
  def up
    add_column :bonuses, :created_by_type, :string
    add_column :bonuses, :updated_by_type, :string
    add_column :retention_chains, :created_by_type, :string
    add_column :retention_chains, :updated_by_type, :string
    add_column :retention_emails, :created_by_type, :string
    add_column :retention_emails, :updated_by_type, :string
    add_column :bonus_audit_logs, :user_type, :string

    backfill_auditable_user_types
  end

  def down
    remove_column :bonuses, :created_by_type
    remove_column :bonuses, :updated_by_type
    remove_column :retention_chains, :created_by_type
    remove_column :retention_chains, :updated_by_type
    remove_column :retention_emails, :created_by_type
    remove_column :retention_emails, :updated_by_type
    remove_column :bonus_audit_logs, :user_type
  end

  private

  def backfill_auditable_user_types
    require "set"

    user_class = Class.new(ActiveRecord::Base) { self.table_name = "users" }
    admin_user_class = Class.new(ActiveRecord::Base) { self.table_name = "admin_users" }
    user_ids = user_class.pluck(:id).to_set
    admin_user_ids = admin_user_class.pluck(:id).to_set

    [
      { table: "bonuses", created: "created_by", created_type: "created_by_type", updated: "updated_by", updated_type: "updated_by_type" },
      { table: "retention_chains", created: "created_by", created_type: "created_by_type", updated: "updated_by", updated_type: "updated_by_type" },
      { table: "retention_emails", created: "created_by", created_type: "created_by_type", updated: "updated_by", updated_type: "updated_by_type" }
    ].each do |entry|
      table_class = Class.new(ActiveRecord::Base) { self.table_name = entry[:table] }
      backfill_type_column(table_class, entry[:created], entry[:created_type], user_ids, admin_user_ids)
      backfill_type_column(table_class, entry[:updated], entry[:updated_type], user_ids, admin_user_ids)
    end

    log_class = Class.new(ActiveRecord::Base) { self.table_name = "bonus_audit_logs" }
    log_class.where(user_type: nil).where.not(user_id: nil).find_each do |log|
      user_type = resolve_user_type(log.user_id, user_ids, admin_user_ids)
      next if user_type.nil?

      log.update_columns(user_type: user_type)
    end
  end

  def backfill_type_column(table_class, id_column, type_column, user_ids, admin_user_ids)
    table_class.where(type_column => nil).where.not(id_column => nil).find_each do |record|
      user_type = resolve_user_type(record.public_send(id_column), user_ids, admin_user_ids)
      next if user_type.nil?

      record.update_columns(type_column => user_type)
    end
  end

  def resolve_user_type(user_id, user_ids, admin_user_ids)
    return if user_id.nil?

    if admin_user_ids.include?(user_id) && !user_ids.include?(user_id)
      "AdminUser"
    elsif user_ids.include?(user_id)
      "User"
    end
  end
end
