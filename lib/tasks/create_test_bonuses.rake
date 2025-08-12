namespace :bonuses do
  desc "Create test deposit bonuses"
  task create_test_deposit_bonuses: :environment do
    puts "Creating test deposit bonuses..."

    # Создаем 5 депозитных бонусов
    bonuses_data = [
      {
        name: "Welcome Bonus 100%",
        code: "WELCOME100",
        bonus_type: "deposit",
        status: "active",

        wager: 1000.00,
        maximum_winnings: 500.00,
        wagering_strategy: "standard",
        availability_start_date: Date.current,
        availability_end_date: Date.current + 30.days,
        user_group: "new_users",
        tags: "welcome, first_deposit, high_value",
        country: "US",
        currency: "USD",
        created_by: 1,
        updated_by: 1,
        project: "VOLNA",
        dsl_tag: "welcome_bonus"
      },
      {
        name: "Reload Bonus 50%",
        code: "RELOAD50",
        bonus_type: "deposit",
        status: "active",

        wager: 750.00,
        maximum_winnings: 250.00,
        wagering_strategy: "standard",
        availability_start_date: Date.current,
        availability_end_date: Date.current + 60.days,
        user_group: "existing_users",
        tags: "reload, weekly, medium_value",
        country: "US",
        currency: "USD",
        created_by: 1,
        updated_by: 1,
        project: "ROX",
        dsl_tag: "reload_bonus"
      },
      {
        name: "VIP Bonus 200%",
        code: "VIP200",
        bonus_type: "deposit",
        status: "active",

        wager: 3000.00,
        maximum_winnings: 2000.00,
        wagering_strategy: "vip",
        availability_start_date: Date.current,
        availability_end_date: Date.current + 90.days,
        user_group: "vip_users",
        tags: "vip, high_roller, exclusive",
        country: "US",
        currency: "USD",
        created_by: 1,
        updated_by: 1,
        project: "FRESH",
        dsl_tag: "vip_bonus"
      },
      {
        name: "Weekend Special 75%",
        code: "WEEKEND75",
        bonus_type: "deposit",
        status: "active",

        wager: 600.00,
        maximum_winnings: 150.00,
        wagering_strategy: "weekend",
        availability_start_date: Date.current.beginning_of_week,
        availability_end_date: Date.current.end_of_week,
        user_group: "all_users",
        tags: "weekend, limited_time, medium_value",
        country: "US",
        currency: "USD",
        created_by: 1,
        updated_by: 1,
        project: "SOL",
        dsl_tag: "weekend_bonus"
      },
      {
        name: "First Deposit 150%",
        code: "FIRST150",
        bonus_type: "deposit",
        status: "active",

        wager: 1500.00,
        maximum_winnings: 750.00,
        wagering_strategy: "first_deposit",
        availability_start_date: Date.current,
        availability_end_date: Date.current + 120.days,
        user_group: "new_users",
        tags: "first_deposit, high_value, exclusive",
        country: "US",
        currency: "USD",
        created_by: 1,
        updated_by: 1,
        project: "JET",
        dsl_tag: "first_deposit_bonus"
      }
    ]

    created_bonuses = []

    bonuses_data.each do |bonus_attrs|
      bonus = Bonus.create!(bonus_attrs)

      # Создаем связанную запись deposit_bonus
      case bonus.name
      when "Welcome Bonus 100%"
        bonus.create_deposit_bonus!(
          deposit_amount_required: 10.00,
          bonus_percentage: 100.00,
          max_bonus_amount: 500.00,
          first_deposit_only: true,
          recurring_eligible: false
        )
      when "Reload Bonus 50%"
        bonus.create_deposit_bonus!(
          deposit_amount_required: 25.00,
          bonus_percentage: 50.00,
          max_bonus_amount: 250.00,
          first_deposit_only: false,
          recurring_eligible: true
        )
      when "VIP Bonus 200%"
        bonus.create_deposit_bonus!(
          deposit_amount_required: 100.00,
          bonus_percentage: 200.00,
          max_bonus_amount: 2000.00,
          first_deposit_only: false,
          recurring_eligible: true
        )
      when "Weekend Special 75%"
        bonus.create_deposit_bonus!(
          deposit_amount_required: 20.00,
          bonus_percentage: 75.00,
          max_bonus_amount: 150.00,
          first_deposit_only: false,
          recurring_eligible: false
        )
      when "First Deposit 150%"
        bonus.create_deposit_bonus!(
          deposit_amount_required: 50.00,
          bonus_percentage: 150.00,
          max_bonus_amount: 750.00,
          first_deposit_only: true,
          recurring_eligible: false
        )
      end

      created_bonuses << bonus
      puts "Created bonus: #{bonus.name} (ID: #{bonus.id}) with deposit bonus settings"
    end

    puts "\nSuccessfully created #{created_bonuses.count} deposit bonuses!"
    puts "Bonus IDs: #{created_bonuses.map(&:id).join(', ')}"
  end

  desc "Create 52 test bonuses of different types for pagination testing"
  task create_52_test_bonuses: :environment do
    puts "Creating 52 test bonuses of different types..."

    # Clear existing test bonuses to avoid duplicates
    Bonus.where("name LIKE ?", "Test Bonus%").destroy_all
    puts "Cleared existing test bonuses"

    bonus_types = %w[deposit input_coupon manual collection groups_update scheduler]
    projects = %w[VOLNA ROX FRESH SOL JET IZZI LEGZO STARDA DRIP MONRO 1GO LEX GIZBO IRWIN FLAGMAN MARTIN P17 ANJUAN NAMASTE]
    statuses = %w[active inactive draft]
    currencies = %w[USD EUR RUB]
    countries = %w[US RU DE FR IT ES]

    created_bonuses = []

    52.times do |i|
      bonus_type = bonus_types[i % bonus_types.length]
      project = projects[i % projects.length]
      status = statuses[i % statuses.length]
      currency = currencies[i % currencies.length]
      country = countries[i % countries.length]

      bonus_attrs = {
        name: "Test Bonus #{i + 1} - #{bonus_type.humanize}",
        code: "TEST#{bonus_type.upcase}#{i + 1}",
        bonus_type: bonus_type,
        status: status,
        wager: rand(100..5000).to_f,
        maximum_winnings: rand(50..2000).to_f,
        wagering_strategy: %w[standard vip weekend first_deposit].sample,
        availability_start_date: Date.current - rand(30).days,
        availability_end_date: Date.current + rand(60..180).days,
        user_group: %w[new_users existing_users vip_users all_users].sample,
        tags: "#{bonus_type}, test, #{project.downcase}",
        country: country,
        currency: currency,
        created_by: 1,
        updated_by: 1,
        project: project,
        dsl_tag: "test_#{bonus_type}_#{i + 1}"
      }

      bonus = Bonus.create!(bonus_attrs)

      # Create type-specific bonus records
      case bonus_type
      when "deposit"
        bonus.create_deposit_bonus!(
          deposit_amount_required: rand(10..200).to_f,
          bonus_percentage: rand(25..200).to_f,
          max_bonus_amount: rand(100..1000).to_f,
          first_deposit_only: [ true, false ].sample,
          recurring_eligible: [ true, false ].sample
        )
      when "input_coupon"
        bonus.create_input_coupon_bonus!(
          coupon_code: "COUPON#{i + 1}",
          usage_limit: rand(10..1000),
          expires_at: Date.current + rand(30..365).days,
          single_use: [ true, false ].sample
        )
      when "manual"
        approval_required = [ true, false ].sample
        auto_apply = approval_required ? false : [ true, false ].sample

        bonus.create_manual_bonus!(
          admin_notes: "Test manual bonus #{i + 1}",
          approval_required: approval_required,
          auto_apply: auto_apply,
          conditions: "Test conditions for bonus #{i + 1}"
        )
      when "collection"
        bonus.create_collect_bonus!(
          collection_type: %w[daily weekly monthly fixed_amount percentage].sample,
          collection_amount: rand(5..100).to_f,
          collection_frequency: %w[daily weekly monthly once].sample,
          collection_limit: rand(5..50)
        )
      when "groups_update"
        bonus.create_groups_update_bonus!(
          target_groups: "[\"group_#{i + 1}\", \"group_#{i + 2}\"]",
          update_type: %w[add_bonus remove_bonus modify_bonus bulk_apply].sample,
          update_parameters: "{\"param_#{i + 1}\": \"value_#{i + 1}\"}",
          batch_size: rand(100..1000)
        )
      when "scheduler"
        bonus.create_scheduler_bonus!(
          schedule_type: %w[recurring one_time cron_based interval_based].sample,
          cron_expression: "0 #{rand(0..23)} * * *",
          next_run_at: Time.current + rand(1..7).days,
          max_executions: rand(10..1000)
        )
      end

      created_bonuses << bonus
      puts "Created bonus #{i + 1}/52: #{bonus.name} (ID: #{bonus.id}, Type: #{bonus_type})"
    end

    puts "\nSuccessfully created #{created_bonuses.count} test bonuses!"
    puts "Bonus IDs: #{created_bonuses.map(&:id).join(', ')}"
    puts "\nDistribution by type:"
    bonus_types.each do |type|
      count = created_bonuses.count { |b| b.bonus_type == type }
      puts "  #{type.humanize}: #{count}"
    end
    puts "\nTotal bonuses in database: #{Bonus.count}"
  end
end
