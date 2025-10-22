module BonusesHelper
  def status_badge_class(status)
    case status
    when "active"
      "bg-success"
    when "inactive"
      "bg-secondary"
    when "expired"
      "bg-danger"
    when "draft"
      "bg-danger"
    else
      "bg-secondary"
    end
  end

  def processing_status_badge_class(status)
    case status
    when "pending"
      "bg-warning"
    when "processing"
      "bg-info"
    when "completed"
      "bg-success"
    when "failed"
      "bg-danger"
    when "paused"
      "bg-secondary"
    else
      "bg-secondary"
    end
  end

  def event_type_options
    [
      [ "Deposit Event", "deposit" ],
      [ "Input Coupon Event", "input_coupon" ],
      [ "Manual Event", "manual" ],
      [ "Collection Event", "collection" ],
      [ "Groups Update Event", "groups_update" ],
      [ "Scheduler Event", "scheduler" ]
    ]
  end

  # Deprecated - use event_type_options instead
  def bonus_type_options
    event_type_options
  end

  def status_options
    [
      [ "Draft", "draft" ],
      [ "Active", "active" ],
      [ "Inactive", "inactive" ],
      [ "Expired", "expired" ]
    ]
  end

  def currency_options
    [
      [ "USD", "USD" ],
      [ "EUR", "EUR" ],
      [ "GBP", "GBP" ],
      [ "BTC", "BTC" ],
      [ "ETH", "ETH" ]
    ]
  end

  def project_options
    # Start with "All" option
    options = [ [ "All", "All" ] ]

    # Add all projects from database
    Project.order(:name).each do |project|
      options << [ project.name, project.name ]
    end

    options
  end

  def dsl_tag_options
    # Start with empty option
    options = [ [ "Select DSL Tag", "" ] ]

    # Add all DSL tags from database
    DslTag.order(:name).each do |dsl_tag|
      options << [ dsl_tag.name, dsl_tag.id ]
    end

    options
  end

  def wagering_strategy_options
    [
      [ "Wager", "wager" ],
      [ "Wager Win", "wager_win" ],
      [ "Wager Free", "wager_free" ],
      [ "Insurance Bonus", "insurance_bonus" ],
      [ "Wager Real", "wager_real" ]
    ]
  end

  def collection_type_options
    [
      [ "Daily", "daily" ],
      [ "Weekly", "weekly" ],
      [ "Monthly", "monthly" ],
      [ "Fixed Amount", "fixed_amount" ],
      [ "Percentage", "percentage" ]
    ]
  end

  def collection_frequency_options
    [
      [ "Daily", "daily" ],
      [ "Weekly", "weekly" ],
      [ "Monthly", "monthly" ],
      [ "Once", "once" ]
    ]
  end

  def schedule_type_options
    [
      [ "Recurring", "recurring" ],
      [ "One Time", "one_time" ],
      [ "Cron Based", "cron_based" ],
      [ "Interval Based", "interval_based" ]
    ]
  end

  def update_type_options
    [
      [ "Add Bonus", "add_bonus" ],
      [ "Remove Bonus", "remove_bonus" ],
      [ "Modify Bonus", "modify_bonus" ],
      [ "Bulk Apply", "bulk_apply" ]
    ]
  end
end
