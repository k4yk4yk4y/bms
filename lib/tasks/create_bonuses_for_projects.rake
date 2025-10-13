namespace :bonuses do
  desc "Create test bonuses for each project (5 bonuses per project)"
  task create_for_projects: :environment do
    puts "Creating test bonuses for each project..."

    # Получаем все проекты
    projects = Project.all

    if projects.empty?
      puts "No projects found. Creating a default project..."
      projects = [ Project.create!(name: "Default Project") ]
    end

    puts "Found #{projects.count} project(s)"

    # Типы событий для создания бонусов
    event_types = %w[deposit input_coupon manual collection scheduler]

    total_created = 0

    projects.each do |project|
      puts "\n📁 Creating bonuses for project: #{project.name}"

      event_types.each_with_index do |event_type, index|
        # Генерируем уникальный код
        code = "#{project.name.upcase.gsub(/[^A-Z0-9]/, '')[0..3]}_#{event_type.upcase}_#{Time.now.to_i}#{index}"

        begin
          bonus = Bonus.create!(
            name: "#{project.name} - #{event_type.humanize} Bonus",
            code: code,
            event: event_type,
            status: "active",
            availability_start_date: Time.current,
            availability_end_date: Time.current + 30.days,
            currencies: [ "USD", "EUR", "BTC" ],
            country: "US",
            user_group: "All",
            tags: "test, #{project.name.downcase.gsub(' ', '_')}",
            maximum_winnings_type: "fixed",
            maximum_winnings: 5000,
            project: project.name,
            description: "Test #{event_type} bonus for #{project.name}"
          )

          puts "  ✅ Created: #{bonus.name} (#{bonus.code})"
          total_created += 1
        rescue ActiveRecord::RecordInvalid => e
          puts "  ❌ Failed to create #{event_type} bonus: #{e.message}"
        end
      end
    end

    puts "\n" + "="*60
    puts "✅ Successfully created #{total_created} bonuses across #{projects.count} project(s)"
    puts "="*60
  end
end
