namespace :audit do
  desc "Create test bonus data with audit logs"
  task create_test_data: :environment do
    puts "Creating test bonus data with audit logs..."

    # Создаем тестового пользователя если его нет
    user = User.find_or_create_by(email: "test@example.com") do |u|
      u.password = "password123"
      u.first_name = "Test"
      u.last_name = "User"
      u.role = "promo_manager"
    end

    # Устанавливаем текущего пользователя для аудита
    Thread.current[:current_user] = user

    # Создаем несколько тестовых бонусов
    bonus_data = [
      {
        name: "Welcome Bonus 100%",
        code: "WELCOME100",
        status: "active",
        event: "deposit",
        project: "VOLNA",
        dsl_tag: "welcome_bonus",
        description: "Welcome bonus 100% on first deposit",
        minimum_deposit: 10.0,
        wager: 35.0,
        maximum_winnings: 1000.0,
        maximum_winnings_type: "fixed",
        availability_start_date: 1.month.ago,
        availability_end_date: 1.month.from_now,
        currencies: [ "USD", "EUR" ],
        currency_minimum_deposits: { "USD" => 10.0, "EUR" => 8.0 }
      },
      {
        name: "Free Spins Friday",
        code: "FREESPIN50",
        status: "draft",
        event: "manual",
        project: "ROX",
        dsl_tag: "friday_spins",
        description: "50 free spins every Friday",
        availability_start_date: Time.current,
        availability_end_date: 3.months.from_now,
        currencies: [ "USD", "EUR", "BTC" ],
        no_more: "weekly"
      },
      {
        name: "Cashback 10%",
        code: "CASHBACK10",
        status: "inactive",
        event: "collection",
        project: "FRESH",
        dsl_tag: "cashback",
        description: "Cashback 10% on losses",
        availability_start_date: 2.weeks.ago,
        availability_end_date: 2.weeks.from_now,
        currencies: [ "USD", "EUR" ],
        wager: 1.0
      }
    ]

    bonus_data.each_with_index do |data, index|
      puts "Creating bonus #{index + 1}: #{data[:name]}"

      bonus = Bonus.create!(data)

      # Создаем несколько записей аудита для демонстрации
      if index == 0
        # Для первого бонуса создаем историю изменений
        bonus.bonus_audit_logs.create!(
          user: user,
          action: "updated",
          changes_data: {
            "status" => [ "draft", "active" ],
            "minimum_deposit" => [ nil, 10.0 ]
          },
          metadata: { ip_address: "127.0.0.1" }
        )

        bonus.bonus_audit_logs.create!(
          user: user,
          action: "updated",
          changes_data: {
            "description" => [ "Welcome bonus", "Welcome bonus 100% on first deposit" ]
          },
          metadata: { ip_address: "127.0.0.1" }
        )
      elsif index == 1
        # Для второго бонуса создаем изменение статуса
        bonus.bonus_audit_logs.create!(
          user: user,
          action: "activated",
          changes_data: { "status" => [ "draft", "active" ] },
          metadata: { ip_address: "127.0.0.1" }
        )
        bonus.bonus_audit_logs.create!(
          user: user,
          action: "deactivated",
          changes_data: { "status" => [ "active", "draft" ] },
          metadata: { ip_address: "127.0.0.1" }
        )
      elsif index == 2
        # Для третьего бонуса создаем несколько изменений
        bonus.bonus_audit_logs.create!(
          user: user,
          action: "updated",
          changes_data: {
            "wager" => [ nil, 1.0 ],
            "currencies" => [ [ "USD" ], [ "USD", "EUR" ] ]
          },
          metadata: { ip_address: "127.0.0.1" }
        )
      end
    end

    puts "Created #{bonus_data.length} test bonuses with audit logs"
    puts "Test user: #{user.email} (password: password123)"
    puts "You can now log in to ActiveAdmin and view the bonuses section"
  end
end
