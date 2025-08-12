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
      "bg-warning"
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

  def bonus_type_options
    [
      [ "Deposit Bonus", "deposit" ],
      [ "Input Coupon Bonus", "input_coupon" ],
      [ "Manual Bonus", "manual" ],
      [ "Collection Bonus", "collection" ],
      [ "Groups Update Bonus", "groups_update" ],
      [ "Scheduler Bonus", "scheduler" ]
    ]
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
    [
      [ "VOLNA", "VOLNA" ],
      [ "ROX", "ROX" ],
      [ "FRESH", "FRESH" ],
      [ "SOL", "SOL" ],
      [ "JET", "JET" ],
      [ "IZZI", "IZZI" ],
      [ "LEGZO", "LEGZO" ],
      [ "STARDA", "STARDA" ],
      [ "DRIP", "DRIP" ],
      [ "MONRO", "MONRO" ],
      [ "1GO", "1GO" ],
      [ "LEX", "LEX" ],
      [ "GIZBO", "GIZBO" ],
      [ "IRWIN", "IRWIN" ],
      [ "FLAGMAN", "FLAGMAN" ],
      [ "MARTIN", "MARTIN" ],
      [ "P17", "P17" ],
      [ "ANJUAN", "ANJUAN" ],
      [ "NAMASTE", "NAMASTE" ]
    ]
  end

  def wagering_strategy_options
    [
      [ "Standard", "standard" ],
      [ "High Roller", "high_roller" ],
      [ "Low Stakes", "low_stakes" ],
      [ "Progressive", "progressive" ]
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
