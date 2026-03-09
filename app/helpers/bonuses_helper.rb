module BonusesHelper
  DCOPY_CURRENCY_SUFFIXES = {
    "rub" => "&#8381;",
    "eur" => "&#8364;",
    "usd" => "&#36;",
    "uah" => "&#8372;",
    "kzt" => "&#8376;",
    "nok" => "kr",
    "pln" => "z&#x142;",
    "try" => "&#8378;",
    "cad" => "c&#36;",
    "aud" => "aud",
    "azn" => "&#8380;",
    "nzd" => "nzd",
    "brl" => "r&#36;",
    "inr" => "&#8377;",
    "ars" => "ars",
    "mxn" => "mxn",
    "pen" => "pen",
    "ngn" => "ngn",
    "zar" => "zar",
    "clp" => "clp",
    "dkk" => "kr",
    "sek" => "kr",
    "ron" => "ron",
    "huf" => "ft",
    "jpy" => "&#165;",
    "btc" => "btc",
    "eth" => "eth",
    "ltc" => "ltc",
    "bch" => "bch",
    "xrp" => "xrp",
    "trx" => "trx",
    "doge" => "doge",
    "usdt" => "usdt"
  }.freeze

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

  def currency_options(project_name = nil)
    currencies =
      if project_name.present? && project_name != "All"
        Project.find_by(name: project_name)&.currencies || []
      else
        Project.available_currencies
      end

    currencies.map { |code| [ code, code ] }
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

  def dcopy_template_for_currency_amounts(amounts_by_currency)
    pairs = dcopy_currency_amount_pairs(amounts_by_currency)
    return "" if pairs.empty?

    pairs.map do |currency, amount|
      code = currency.to_s.downcase
      suffix = DCOPY_CURRENCY_SUFFIXES.fetch(code, code)
      %(#{dcopy_currency_condition(code)}#{dcopy_format_amount(amount)}&nbsp;#{suffix}{{/equals}})
    end.join
  end

  def dcopy_minimum_deposit_amounts(bonus)
    return {} unless bonus

    bonus.effective_currency_minimum_deposits
  end

  def dcopy_freespin_bet_amounts(reward, bonus:)
    return {} unless reward

    values = reward.currency_freespin_bet_levels
    return values if values.present?
    return {} if reward.bet_level.blank?

    currencies = bonus.currencies.presence || bonus.project_currencies.presence || []
    return {} if currencies.blank?

    currencies.index_with { reward.bet_level }
  end

  def dcopy_bonus_reward_maximum_amounts(reward)
    return {} unless reward

    reward.currency_maximum_amounts.presence || {}
  end

  def dcopy_fixed_bonus_reward_amounts(reward, bonus:)
    return {} unless reward
    return {} if reward.percentage.present?

    values = reward.currency_amounts
    return values if values.present?
    return {} if reward.amount.blank?

    currencies = bonus.currencies.presence || bonus.project_currencies.presence || []
    return {} if currencies.blank?

    currencies.index_with { reward.amount }
  end

  private

  def dcopy_currency_condition(currency_code)
    %({{#equals account_currency "#{currency_code}" }})
  end

  def dcopy_currency_amount_pairs(amounts_by_currency)
    return [] unless amounts_by_currency.respond_to?(:each)

    amounts_by_currency.each_with_object([]) do |(currency, amount), pairs|
      next if currency.blank? || amount.blank?

      pairs << [ currency, amount ]
    end
  end

  def dcopy_format_amount(amount)
    raw_amount = amount.is_a?(String) ? amount.strip : amount.to_s
    normalized = raw_amount.tr(",", ".")
    decimal = BigDecimal(normalized)

    formatted = if decimal.frac.zero?
      decimal.to_i.to_s
    else
      decimal.to_s("F").sub(/\.?0+$/, "")
    end

    formatted.tr(".", ",")
  rescue ArgumentError, TypeError
    raw_amount.to_s.tr(".", ",")
  end
end
