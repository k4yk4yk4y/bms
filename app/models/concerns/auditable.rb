module Auditable
  extend ActiveSupport::Concern

  included do
    before_create :set_created_by
    before_update :set_updated_by
    after_create :audit_log_creation
    after_update :audit_log_changes
    after_destroy :audit_log_deletion
  end

  private

  def set_created_by
    self.created_by = current_user&.id if respond_to?(:created_by) && current_user
  end

  def set_updated_by
    self.updated_by = current_user&.id if respond_to?(:updated_by) && current_user
  end

  def audit_log_creation
    return unless respond_to?(:log_creation) && current_user
    self.log_creation(current_user)
  end

  def audit_log_changes
    return unless respond_to?(:log_update) && saved_changes.any? && current_user

    # Filter out changes we don't want to log
    changes_to_log = saved_changes.except("updated_at", "updated_by")
    self.log_update(current_user, changes_to_log) if changes_to_log.any?
  end

  def audit_log_deletion
    return unless respond_to?(:log_deletion) && current_user
    self.log_deletion(current_user)
  end

  def current_user
    # Try to get current user from different sources
    RequestStore.store[:current_user] ||
    Thread.current[:current_user] ||
    (defined?(Current) && Current.user)
  end
end
