namespace :marketing do
  desc "Create test marketing requests data with new partner rules"
  task create_test_data: :environment do
    puts "Creating test marketing requests with partner rules..."

    # Создаем уникальные STAG для разных партнеров
    # Согласно правилу 3: один партнер - одна заявка
    unique_partners = [
      {
        stag: "partner_casino_1",
        manager: "anna.ivanova@bms.com",
        email: "anna@casino1.com",
        platform: "https://casino1.com",
        type: "promo_webs_50",
        codes: [ "CASINO1_WELCOME", "CASINO1_BONUS" ]
      },
      {
        stag: "partner_casino_2",
        manager: "petr.sidorov@bms.com",
        email: "petr@casino2.com",
        platform: "https://casino2.com",
        type: "promo_webs_100",
        codes: [ "CASINO2_MEGA", "CASINO2_SUPER", "CASINO2_ULTRA" ]
      },
      {
        stag: "partner_casino_3",
        manager: "maria.petrova@bms.com",
        email: "maria@casino3.com",
        platform: "Партнерская площадка для казино, текстовое описание без ссылки",
        type: "promo_no_link_50",
        codes: [ "CASINO3_PROMO" ]
      },
      {
        stag: "partner_casino_4",
        manager: "dmitry.kozlov@bms.com",
        email: "dmitry@casino4.com",
        platform: nil,
        type: "promo_no_link_100",
        codes: [ "CASINO4_WELCOME", "CASINO4_RELOAD" ]
      },
      {
        stag: "partner_casino_5",
        manager: "elena.volkova@bms.com",
        email: "elena@casino5.com",
        platform: "https://casino5-partners.com",
        type: "deposit_bonuses_partners",
        codes: [ "CASINO5_DEPOSIT", "CASINO5_WEEKEND", "CASINO5_VIP" ]
      }
    ]

    unique_partners.each_with_index do |partner_data, index|
      # Проверяем, существует ли уже заявка с таким STAG
      existing_request = MarketingRequest.find_by(stag: partner_data[:stag])

      if existing_request
        puts "⊘ Заявка для партнера #{partner_data[:stag]} уже существует (ID: #{existing_request.id}), пропускаем"
      else
        # Создаем заявку для каждого уникального партнера
        request = MarketingRequest.create!(
          manager: partner_data[:manager],
          platform: partner_data[:platform],
          partner_email: partner_data[:email],
          promo_code: partner_data[:codes].join(", "),  # Несколько кодов в одной заявке
          stag: partner_data[:stag],
          status: [ "pending", "activated", "rejected" ].sample,
          request_type: partner_data[:type],
          activation_date: rand(2) == 0 ? nil : rand(3).days.ago
        )

        puts "✓ Создана заявка для партнера #{partner_data[:stag]}: #{partner_data[:codes].length} кодов"
      end
    end

    # Создаем дополнительные заявки для других типов (без дублирования STAG)
    additional_requests = [
      {
        manager: "igor.semenov@bms.com",
        platform: "https://additional-partner.com",
        email: "igor@additional.com",
        stag: "additional_partner_1",
        type: "promo_no_link_125",
        codes: [ "ADDITIONAL_125" ]
      },
      {
        manager: "olga.krasova@bms.com",
        platform: nil,
        email: "olga@minimal.com",
        stag: "minimal_partner",
        type: "promo_no_link_150",
        codes: [ "MINIMAL_150", "MINIMAL_EXTRA" ]
      }
    ]

    additional_requests.each do |req_data|
      # Проверяем, существует ли уже заявка с таким STAG
      existing_request = MarketingRequest.find_by(stag: req_data[:stag])

      if existing_request
        puts "⊘ Заявка для партнера #{req_data[:stag]} уже существует (ID: #{existing_request.id}), пропускаем"
      else
        MarketingRequest.create!(
          manager: req_data[:manager],
          platform: req_data[:platform],
          partner_email: req_data[:email],
          promo_code: req_data[:codes].join(", "),
          stag: req_data[:stag],
          status: [ "pending", "activated" ].sample,
          request_type: req_data[:type],
          activation_date: rand(2) == 0 ? nil : rand(2).days.ago
        )
        puts "✓ Создана заявка для партнера #{req_data[:stag]}: #{req_data[:codes].length} кодов"
      end
    end

    puts "\nСоздано #{MarketingRequest.count} заявок согласно партнерским правилам"

    # Выводим статистику
    puts "\nРаспределение по типам:"
    MarketingRequest::REQUEST_TYPES.each do |type|
      count = MarketingRequest.by_request_type(type).count
      puts "  #{MarketingRequest::REQUEST_TYPE_LABELS[type]}: #{count} заявок"
    end

    puts "\nСтатистика по статусам:"
    MarketingRequest::STATUSES.each do |status|
      count = MarketingRequest.by_status(status).count
      puts "  #{MarketingRequest::STATUS_LABELS[status]}: #{count} заявок"
    end

    puts "\nВсе STAG уникальны: #{MarketingRequest.distinct.count(:stag) == MarketingRequest.count}"
    puts "Проверка правил партнеров завершена!"
  end

  desc "Clear all marketing requests"
  task clear_data: :environment do
    count = MarketingRequest.count
    MarketingRequest.destroy_all
    puts "Deleted #{count} marketing requests"
  end
end
