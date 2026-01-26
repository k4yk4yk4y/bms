module ApplicationHelper
  def status_class(status)
    case status
    when "active"
      :ok
    when "inactive"
      :error
    when "draft"
      :warning
    when "expired"
      :default
    else
      :default
    end
  end

  def action_status_class(action)
    case action
    when "created"
      :ok
    when "updated"
      :warning
    when "deleted"
      :error
    when "activated"
      :ok
    when "deactivated"
      :error
    else
      :default
    end
  end

  def can_read_users?
    can?(:read, User)
  end

  def user_profile_link(user)
    return unless user&.email.present?

    if user.is_a?(AdminUser)
      return user.email
    end

    return unless can_read_users?

    link_to user.email, user_path(user)
  end
end
