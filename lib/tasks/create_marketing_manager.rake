# frozen_string_literal: true

namespace :user do
  desc 'Создать пользователя с ролью marketing_manager'
  task create_marketing_manager: :environment do
    email = ENV['EMAIL'] || 'marketing_manager@example.com'
    password = ENV['PASSWORD'] || 'password123'
    first_name = ENV['FIRST_NAME'] || 'Marketing'
    last_name = ENV['LAST_NAME'] || 'Manager'
    
    puts "Создание marketing_manager пользователя..."
    puts "Email: #{email}"
    puts "Password: #{password}"
    puts "Name: #{first_name} #{last_name}"
    
    begin
      user = User.find_or_create_by(email: email) do |u|
        u.password = password
        u.password_confirmation = password
        u.first_name = first_name
        u.last_name = last_name
        u.role = :marketing_manager
      end
      
      if user.persisted?
        # Обновляем роль, если пользователь уже существовал
        unless user.marketing_manager?
          user.update!(role: :marketing_manager)
          puts "✓ Роль обновлена на marketing_manager"
        end
        
        puts "✓ Пользователь с ролью marketing_manager создан успешно!"
        puts "ID: #{user.id}"
        puts "Email: #{user.email}"
        puts "Role: #{user.display_role}"
        puts "Full name: #{user.full_name}"
        
        puts "\nДля входа используйте:"
        puts "Email: #{user.email}"
        puts "Password: #{password}"
        
        puts "\nПроверим права доступа:"
        ability = Ability.new(user)
        
        puts "- Доступ к Marketing: #{ability.can?(:manage, MarketingRequest) ? '✓' : '✗'}"
        puts "- Доступ к Bonuses: #{ability.can?(:read, Bonus) ? '✓' : '✗'}"
        puts "- Доступ к Settings: #{ability.can?(:access, :settings) ? '✓' : '✗'}"
        puts "- Доступ к API: #{ability.can?(:access, :api) ? '✓' : '✗'}"
        
      else
        puts "❌ Ошибка создания пользователя:"
        user.errors.full_messages.each do |error|
          puts "  - #{error}"
        end
      end
      
    rescue StandardError => e
      puts "❌ Ошибка: #{e.message}"
      puts e.backtrace.join("\n") if ENV['DEBUG']
    end
  end
  
  desc 'Показать всех пользователей с ролью marketing_manager'
  task list_marketing_managers: :environment do
    marketing_managers = User.marketing_managers.includes(:id)
    
    puts "Пользователи с ролью marketing_manager:"
    puts "=" * 50
    
    if marketing_managers.any?
      marketing_managers.each do |user|
        puts "ID: #{user.id}"
        puts "Email: #{user.email}"
        puts "Name: #{user.full_name}"
        puts "Created: #{user.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        puts "-" * 30
      end
      
      puts "Всего marketing_manager пользователей: #{marketing_managers.count}"
    else
      puts "Нет пользователей с ролью marketing_manager"
    end
  end
  
  desc 'Удалить marketing_manager пользователя по email'
  task :delete_marketing_manager, [:email] => :environment do |task, args|
    email = args[:email] || ENV['EMAIL']
    
    if email.blank?
      puts "❌ Необходимо указать email:"
      puts "rake user:delete_marketing_manager[email@example.com]"
      puts "или"
      puts "EMAIL=email@example.com rake user:delete_marketing_manager"
      exit 1
    end
    
    user = User.find_by(email: email)
    
    if user.nil?
      puts "❌ Пользователь с email '#{email}' не найден"
      exit 1
    end
    
    unless user.marketing_manager?
      puts "❌ Пользователь '#{email}' не имеет роль marketing_manager"
      puts "Текущая роль: #{user.display_role}"
      exit 1
    end
    
    puts "Удаление marketing_manager пользователя:"
    puts "Email: #{user.email}"
    puts "Name: #{user.full_name}"
    
    print "Вы уверены? (y/N): "
    confirmation = STDIN.gets.chomp.downcase
    
    if confirmation == 'y' || confirmation == 'yes'
      user.destroy!
      puts "✓ Пользователь удален успешно"
    else
      puts "Операция отменена"
    end
  end
  
  desc 'Тест прав доступа для marketing_manager'
  task test_marketing_manager_abilities: :environment do
    marketing_manager = User.marketing_managers.first
    
    if marketing_manager.nil?
      puts "❌ Нет пользователей с ролью marketing_manager"
      puts "Создайте пользователя: rake user:create_marketing_manager"
      exit 1
    end
    
    puts "Тестирование прав доступа для #{marketing_manager.email}..."
    puts "=" * 50
    
    ability = Ability.new(marketing_manager)
    
    # Тесты положительных разрешений
    positive_tests = [
      [:manage, MarketingRequest, "Управление маркетинговыми заявками"],
      [:read, ActiveAdmin::Page, "Доступ к Dashboard"],
      [:read, User, "Чтение собственного профиля"],
      [:update, User, "Обновление собственного профиля"]
    ]
    
    # Тесты отрицательных разрешений  
    negative_tests = [
      [:read, Bonus, "Чтение бонусов"],
      [:manage, Bonus, "Управление бонусами"],
      [:manage, BonusTemplate, "Управление шаблонами бонусов"],
      [:access, :settings, "Доступ к настройкам"],
      [:manage, :settings, "Управление настройками"],
      [:access, :api, "Доступ к API"],
      [:manage, :api, "Управление API"]
    ]
    
    puts "РАЗРЕШЕННЫЕ действия (должны быть ✓):"
    positive_tests.each do |action, resource, description|
      target = resource.is_a?(Class) && resource == User ? User.new(id: marketing_manager.id) : resource
      result = ability.can?(action, target)
      status = result ? "✓" : "✗"
      puts "  #{status} #{description}"
    end
    
    puts "\nЗАПРЕЩЕННЫЕ действия (должны быть ✗):"
    negative_tests.each do |action, resource, description|
      result = ability.can?(action, resource)
      status = result ? "✗ (ОШИБКА!)" : "✓"
      puts "  #{status} #{description}"
    end
    
    puts "\nТест завершен!"
  end
end
