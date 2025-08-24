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
end
