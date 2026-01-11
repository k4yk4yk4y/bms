namespace :seed do
  desc "Create projects, bonuses, marketing requests, and retention data for deploy"
  task deploy_data: :environment do
    require "set"

    manager_email = "p.rusakevich@jetmail.cc"
    manager = User.find_or_create_by!(email: manager_email) do |user|
      user.password = SecureRandom.hex(16)
      user.role = :marketing_manager
    end

    project_names = %w[VOLNA ROX FRESH SOL]
    projects = project_names.map { |name| Project.find_or_create_by!(name: name) }

    event_types = Bonus::EVENT_TYPES.first(5)
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
            currencies: %w[USD EUR BTC],
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
          puts "Bonus #{bonus.code} already exists"
        end

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
