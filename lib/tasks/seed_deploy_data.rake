namespace :seed do
  desc "Create projects, bonuses, marketing requests, and retention data for deploy"
  task deploy_data: :environment do
    require "bigdecimal"
    require "set"

    seed_currency_minimum_deposits = {
      "RUB" => 5000.0,
      "EUR" => 50.0,
      "USD" => 50.0,
      "UAH" => 2500.0,
      "KZT" => 25_000.0,
      "NOK" => 250.0,
      "PLN" => 250.0,
      "TRY" => 2500.0,
      "CAD" => 50.0,
      "AUD" => 50.0,
      "AZN" => 100.0,
      "NZD" => 100.0,
      "BRL" => 200.0,
      "INR" => 5000.0,
      "ARS" => 50_000.0,
      "MXN" => 1000.0,
      "PEN" => 250.0,
      "NGN" => 100_000.0,
      "ZAR" => 1000.0,
      "CLP" => 25_000.0,
      "DKK" => 500.0,
      "SEK" => 500.0,
      "RON" => 250.0,
      "HUF" => 25_000.0,
      "JPY" => 12_500.0,
      # CurrencyManagement сейчас ограничивает значения 2 знаками после запятой.
      "BTC" => 0.55,
      "ETH" => 0.13,
      "LTC" => 0.55,
      "BCH" => 0.11,
      "XRP" => 20.0,
      "TRX" => 167.0,
      "DOGE" => 269.0,
      "USDT" => 50.0
    }.freeze

    default_project_currencies = seed_currency_minimum_deposits.keys.freeze

    fixed_bonus_currency_amounts = seed_currency_minimum_deposits.transform_values do |amount|
      scaled = (BigDecimal(amount.to_s) * BigDecimal("0.2")).round(2)
      scaled = BigDecimal("0.1") if scaled.zero?
      scaled.to_f
    end.freeze

    maximum_bonus_currency_amounts = fixed_bonus_currency_amounts.transform_values do |amount|
      (BigDecimal(amount.to_s) * BigDecimal("2")).round(2).to_f
    end.freeze

    freespin_bet_levels = seed_currency_minimum_deposits.transform_values do |amount|
      case amount
      when 10_000.. then 10.0
      when 1_000...10_000 then 5.0
      when 100...1_000 then 1.0
      else 0.2
      end
    end.freeze

    bonus_buy_amounts = fixed_bonus_currency_amounts.transform_values do |amount|
      scaled = (BigDecimal(amount.to_s) * BigDecimal("1.5")).round(2)
      [ scaled.to_f, 0.1 ].max
    end.freeze

    reward_values_for_bonus = lambda do |bonus|
      currencies = bonus.currencies.presence || default_project_currencies

      {
        minimum_deposits: seed_currency_minimum_deposits.slice(*currencies),
        fixed_amounts: fixed_bonus_currency_amounts.slice(*currencies),
        maximum_amounts: maximum_bonus_currency_amounts.slice(*currencies),
        freespin_levels: freespin_bet_levels.slice(*currencies),
        bonus_buy_amounts: bonus_buy_amounts.slice(*currencies)
      }
    end

    ensure_deposit_seed_rewards = lambda do |bonus|
      values = reward_values_for_bonus.call(bonus)

      merged_deposits = values[:minimum_deposits].merge(bonus.currency_minimum_deposits.to_h)
      if merged_deposits != bonus.currency_minimum_deposits.to_h
        bonus.currency_minimum_deposits = merged_deposits
        bonus.save!
      end

      fixed_code = "#{bonus.code}_FIXED"
      fixed_reward = bonus.bonus_rewards.find_by(code: fixed_code) ||
                     bonus.bonus_rewards.where(reward_type: "bonus", percentage: nil).first ||
                     bonus.bonus_rewards.build(code: fixed_code)
      fixed_reward.code = fixed_code
      fixed_reward.reward_type = "bonus"
      fixed_reward.amount = nil
      fixed_reward.percentage = nil
      fixed_reward.currency_amounts = values[:fixed_amounts]
      fixed_reward.currency_maximum_amounts = {}
      fixed_reward.user_can_have_duplicates = true
      fixed_reward.save!

      percent_code = "#{bonus.code}_PERCENT"
      percentage_reward = bonus.bonus_rewards.find_by(code: percent_code) ||
                          bonus.bonus_rewards.where.not(percentage: nil).first ||
                          bonus.bonus_rewards.build(code: percent_code)
      percentage_reward.code = percent_code
      percentage_reward.reward_type = "bonus"
      percentage_reward.amount = nil
      percentage_reward.percentage = 100
      percentage_reward.currency_amounts = {}
      percentage_reward.currency_maximum_amounts = values[:maximum_amounts]
      percentage_reward.user_can_have_duplicates = false
      percentage_reward.save!

      fs_code = "#{bonus.code}_FS"
      freespin_reward = bonus.freespin_rewards.find_by(code: fs_code) ||
                        bonus.freespin_rewards.first ||
                        bonus.freespin_rewards.build(code: fs_code)
      freespin_reward.code = fs_code
      freespin_reward.spins_count = 50
      freespin_reward.games = [ "book_of_dead", "starburst" ]
      freespin_reward.currency_freespin_bet_levels = values[:freespin_levels]
      freespin_reward.deposit_percentage = 100
      freespin_reward.save!

      buy_code = "#{bonus.code}_BUY"
      bonus_buy_reward = bonus.bonus_buy_rewards.find_by(code: buy_code) ||
                         bonus.bonus_buy_rewards.first ||
                         bonus.bonus_buy_rewards.build(code: buy_code)
      bonus_buy_reward.code = buy_code
      bonus_buy_reward.multiplier = 1.5
      bonus_buy_reward.games = [ "book_of_dead", "starburst" ]
      bonus_buy_reward.currency_buy_amounts = values[:bonus_buy_amounts]
      bonus_buy_reward.deposit_percentage = 100
      bonus_buy_reward.save!
    end

    User.roles.keys.each do |key|
      role = Role.find_or_initialize_by(key: key)
      role.name ||= key.tr("_", " ").split.map(&:capitalize).join(" ")
      # Keep role permissions up to date with the full catalog, including
      # project separation and permanent bonuses visibility keys.
      default_permissions = Role.default_permissions_for(key)
      merged_permissions = Role.normalize_permissions_hash(default_permissions.merge(role.permissions.to_h))
      merged_permissions["projects"] = default_permissions["projects"] if default_permissions["projects"].present?
      merged_permissions["permanent_bonuses"] = default_permissions["permanent_bonuses"] if default_permissions["permanent_bonuses"].present?
      role.permissions = merged_permissions
      role.admin_panel_access = true if key.to_s == "admin"
      role.admin_panel_access = false if role.new_record? && key.to_s != "admin"
      role.save!
    end

    Role.find_each do |role|
      normalized = Role.normalize_permissions_hash(role.permissions)
      next if normalized == role.permissions

      role.update!(permissions: normalized)
    end

    manager_email = "p.rusakevich@jetmail.cc"
    manager = User.find_or_initialize_by(email: manager_email)
    if manager.new_record?
      manager.first_name = "Pavel"
      manager.last_name = "Rusakevich"
    end
    manager.password = "p.rusakevich"
    manager.password_confirmation = "p.rusakevich"
    manager.role = :admin
    manager.save!

    User.roles.keys.each do |role_key|
      email = "seed_#{role_key}@example.com"
      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.first_name = role_key.to_s.split("_").map(&:capitalize).join(" ")
        user.last_name = "Seed"
      end
      user.password = "123123"
      user.password_confirmation = "123123"
      user.role = role_key
      user.save!
    end

    project_names = %w[VOLNA ROX FRESH SOL]
    projects = project_names.map do |name|
      project = Project.find_or_initialize_by(name: name)

      merged_currencies = (project.currencies.presence || []) | default_project_currencies
      project.currencies = merged_currencies
      project.save! if project.new_record? || project.changed?
      project
    end

    event_types = Bonus::EVENT_TYPES
    bonuses_by_project = {}

    projects.each do |project|
      bonuses = []

      event_types.each_with_index do |event_type, index|
        code = "#{project.name}_#{event_type}_#{index + 1}".upcase
        bonus = Bonus.find_or_initialize_by(code: code)

        if bonus.new_record?
          bonus.assign_attributes(
            name: "#{project.name} #{event_type.humanize} Bonus #{index + 1}",
            event: event_type,
            status: "active",
            availability_start_date: Time.current,
            availability_end_date: Time.current + 30.days,
            currencies: project.currencies.presence || default_project_currencies,
            country: "US",
            user_group: "All",
            tags: "seed,#{project.name.downcase}",
            maximum_winnings_type: "fixed",
            maximum_winnings: 1000,
            project: project.name,
            description: "Seed #{event_type} bonus for #{project.name}",
            created_by: manager.id,
            updated_by: manager.id
          )
          bonus.save!
          puts "Created bonus #{bonus.code} for #{project.name}"
        else
          merged_bonus_currencies = (bonus.currencies.presence || []) | (project.currencies.presence || default_project_currencies)
          if merged_bonus_currencies != bonus.currencies
            bonus.currencies = merged_bonus_currencies
            bonus.save!
          end

          puts "Bonus #{bonus.code} already exists"
        end

        ensure_deposit_seed_rewards.call(bonus) if bonus.event == "deposit"
        bonuses << bonus
      end

      bonuses_by_project[project.id] = bonuses
    end

    existing_codes = MarketingRequest.pluck(:promo_code)
                                     .flat_map { |codes| codes.to_s.split(/[,\n\r]+/).map(&:strip) }
                                     .reject(&:blank?)
                                     .to_set

    MarketingRequest::REQUEST_TYPES.each do |request_type|
      2.times do |index|
        stag = "#{request_type}_partner_#{index + 1}"
        if MarketingRequest.exists?(stag: stag)
          puts "Marketing request with STAG #{stag} already exists"
          next
        end

        base_code = "PROMO_#{request_type.upcase}_#{index + 1}"
        promo_code = base_code
        suffix = 1
        while existing_codes.include?(promo_code)
          promo_code = "#{base_code}_#{suffix}"
          suffix += 1
        end
        existing_codes.add(promo_code)

        MarketingRequest.create!(
          manager: manager_email,
          platform: "https://#{stag}.example.com",
          partner_email: "partner_#{request_type}_#{index + 1}@example.com",
          promo_code: promo_code,
          stag: stag,
          status: MarketingRequest::STATUSES.sample,
          request_type: request_type,
          activation_date: nil
        )

        puts "Created marketing request #{stag} (#{request_type})"
      end
    end

    projects.each do |project|
      bonuses = bonuses_by_project[project.id] || []

      2.times do |chain_index|
        chain_name = "Retention #{project.name} Chain #{chain_index + 1}"
        chain = RetentionChain.find_or_initialize_by(name: chain_name, project_id: project.id)

        if chain.new_record?
          chain.assign_attributes(
            status: "active",
            created_by: manager.id,
            updated_by: manager.id
          )
          chain.save!
          puts "Created retention chain #{chain_name}"
        else
          puts "Retention chain #{chain_name} already exists"
        end

        3.times do |email_index|
          subject = "#{project.name} Chain #{chain_index + 1} Email #{email_index + 1}"
          email = RetentionEmail.find_or_initialize_by(retention_chain_id: chain.id, subject: subject)

          if email.new_record?
            email.assign_attributes(
              preheader: "Preheader #{email_index + 1} for #{project.name}",
              header: "Header #{email_index + 1} for #{project.name}",
              body: "Retention email #{email_index + 1} for #{project.name}.",
              send_timing: "day_#{email_index + 1}",
              description: "Seed retention email #{email_index + 1} for #{project.name}",
              status: "active",
              created_by: manager.id,
              updated_by: manager.id
            )
            email.save!
            puts "Created retention email #{subject}"
          else
            puts "Retention email #{subject} already exists"
          end

          next if bonuses.empty?

          bonus = bonuses[email_index % bonuses.length]
          RetentionEmailBonus.find_or_create_by!(retention_email: email, bonus: bonus)
        end
      end
    end
  end
end
