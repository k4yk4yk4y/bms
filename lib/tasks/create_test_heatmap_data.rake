namespace :heatmap do
  desc "Create test bonus data for July 2025 to test heatmap calendar"
  task create_test_data: :environment do
    puts "Creating test bonus data for July 2025..."
    
    # Удаляем существующие тестовые данные для июля 2025
    july_start = Date.new(2025, 7, 1).beginning_of_day
    july_end = Date.new(2025, 7, 31).end_of_day
    
    existing_count = Bonus.where(availability_start_date: july_start..july_end).count
    if existing_count > 0
      puts "Found #{existing_count} existing bonuses for July 2025. Deleting..."
      Bonus.where(availability_start_date: july_start..july_end).destroy_all
    end
    
    # Создаем тестовые данные с разным количеством бонусов на разные даты
    test_data = [
      # Белые дни (0 бонусов) - будут созданы автоматически для дат без данных
      
      # Светло-зеленые дни (1-2 бонуса)
      { date: Date.new(2025, 7, 1), count: 1, types: ['deposit'] },
      { date: Date.new(2025, 7, 3), count: 2, types: ['deposit', 'manual'] },
      { date: Date.new(2025, 7, 8), count: 1, types: ['input_coupon'] },
      { date: Date.new(2025, 7, 12), count: 2, types: ['collection', 'scheduler'] },
      
      # Средне-зеленые дни (3-4 бонуса)
      { date: Date.new(2025, 7, 5), count: 3, types: ['deposit', 'manual', 'input_coupon'] },
      { date: Date.new(2025, 7, 10), count: 4, types: ['deposit', 'collection', 'scheduler', 'groups_update'] },
      { date: Date.new(2025, 7, 18), count: 3, types: ['manual', 'input_coupon', 'collection'] },
      { date: Date.new(2025, 7, 22), count: 4, types: ['deposit', 'manual', 'scheduler', 'input_coupon'] },
      
      # Темно-зеленые дни (5-6 бонусов)
      { date: Date.new(2025, 7, 7), count: 5, types: ['deposit', 'manual', 'input_coupon', 'collection', 'scheduler'] },
      { date: Date.new(2025, 7, 14), count: 6, types: ['deposit', 'manual', 'input_coupon', 'collection', 'scheduler', 'groups_update'] },
      { date: Date.new(2025, 7, 25), count: 5, types: ['deposit', 'deposit', 'manual', 'input_coupon', 'collection'] },
      
      # Переходные зелено-красные дни (7-8 бонусов)
      { date: Date.new(2025, 7, 15), count: 7, types: ['deposit', 'deposit', 'manual', 'input_coupon', 'collection', 'scheduler', 'groups_update'] },
      { date: Date.new(2025, 7, 20), count: 8, types: ['deposit', 'deposit', 'manual', 'manual', 'input_coupon', 'collection', 'scheduler', 'groups_update'] },
      
      # Красные дни (9-10+ бонусов)
      { date: Date.new(2025, 7, 16), count: 9, types: ['deposit', 'deposit', 'deposit', 'manual', 'manual', 'input_coupon', 'collection', 'scheduler', 'groups_update'] },
      { date: Date.new(2025, 7, 28), count: 10, types: ['deposit', 'deposit', 'deposit', 'manual', 'manual', 'input_coupon', 'input_coupon', 'collection', 'scheduler', 'groups_update'] },
      { date: Date.new(2025, 7, 31), count: 12, types: ['deposit', 'deposit', 'deposit', 'manual', 'manual', 'manual', 'input_coupon', 'input_coupon', 'collection', 'collection', 'scheduler', 'groups_update'] },
    ]
    
    created_bonuses = 0
    
    test_data.each do |data|
      date = data[:date]
      count = data[:count]
      types = data[:types]
      
      puts "Creating #{count} bonuses for #{date.strftime('%Y-%m-%d')}"
      
      count.times do |i|
        bonus_type = types[i % types.length]
        
        # Создаем основной бонус
        bonus = Bonus.create!(
          name: "Test #{bonus_type.humanize} Bonus #{date.strftime('%m%d')}-#{i+1}",
          bonus_type: bonus_type,
          status: 'active',
          availability_start_date: date.beginning_of_day + i.minutes,
          availability_end_date: date.end_of_day,
          currency: 'USD',
          country: 'US',
          user_group: 'test_users',
          tags: 'heatmap_test, july_2025'
        )
        
        # Создаем связанную запись в зависимости от типа бонуса
        case bonus_type
        when 'deposit'
          DepositBonus.create!(
            bonus: bonus,
            deposit_amount_required: 50.0,
            bonus_percentage: 100.0,
            max_bonus_amount: 500.0,
            first_deposit_only: false,
            recurring_eligible: true
          )
        when 'input_coupon'
          InputCouponBonus.create!(
            bonus: bonus,
            coupon_code: "TEST#{date.strftime('%m%d')}#{i+1}#{SecureRandom.hex(3)}",
            usage_limit: 100,
            usage_count: 0,
            expires_at: Date.current.end_of_day + 1.week,
            single_use: false
          )
        when 'manual'
          ManualBonus.create!(
            bonus: bonus,
            admin_notes: "Test manual bonus for heatmap testing",
            approval_required: false,
            auto_apply: true,
            conditions: "Test conditions for heatmap"
          )
        when 'collection'
          CollectBonus.create!(
            bonus: bonus,
            collection_type: 'daily',
            collection_amount: 25.0,
            collection_frequency: 'daily',
            collection_limit: 1,
            collected_count: 0
          )
        when 'groups_update'
          GroupsUpdateBonus.create!(
            bonus: bonus,
            target_groups: '["test_group_1", "test_group_2"]',
            update_type: 'bulk_apply',
            update_parameters: '{"amount": 100}',
            batch_size: 50,
            processing_status: 'completed'
          )
        when 'scheduler'
          SchedulerBonus.create!(
            bonus: bonus,
            schedule_type: 'recurring',
            cron_expression: '0 12 * * *',
            next_run_at: date.beginning_of_day + 12.hours,
            last_run_at: date.beginning_of_day,
            execution_count: 1,
            max_executions: 30
          )
        end
        
        created_bonuses += 1
      end
    end
    
    puts "✅ Successfully created #{created_bonuses} test bonuses for July 2025"
    puts "📊 Heatmap distribution:"
    puts "   White (0): #{31 - test_data.length} days"
    puts "   Light green (1-2): #{test_data.select { |d| d[:count].between?(1, 2) }.length} days"
    puts "   Medium green (3-4): #{test_data.select { |d| d[:count].between?(3, 4) }.length} days"
    puts "   Dark green (5-6): #{test_data.select { |d| d[:count].between?(5, 6) }.length} days"
    puts "   Green-red (7-8): #{test_data.select { |d| d[:count].between?(7, 8) }.length} days"
    puts "   Red (9-10+): #{test_data.select { |d| d[:count] >= 9 }.length} days"
    puts ""
    puts "🌐 Navigate to http://localhost:3000/heatmap?year=2025&month=7 to see the results!"
  end
end
