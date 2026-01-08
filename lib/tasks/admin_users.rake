namespace :admin do
  desc "Creates a default admin user using ADMIN_EMAIL and ADMIN_PASSWORD environment variables"
  task create_default: :environment do
    # Убедитесь, что модель AdminUser существует, иначе Active Admin не будет работать.
    if defined?(AdminUser)
      email = ENV["ADMIN_EMAIL"]
      password = ENV["ADMIN_PASSWORD"]

      unless email.present? && password.present?
        puts "🚨 ОШИБКА: Пожалуйста, задайте переменные окружения ADMIN_EMAIL и ADMIN_PASSWORD."
        puts "Использование: rake admin:create_default ADMIN_EMAIL=user@example.com ADMIN_PASSWORD=secret"
        exit 1
      end

      # Проверяем, существует ли уже пользователь с таким email
      if AdminUser.find_by(email: email)
        puts "✅ Администратор с email '#{email}' уже существует. Пропускаем создание."
      else
        # Создание нового администратора
        admin = AdminUser.create!(
          email: email,
          password: password,
          password_confirmation: password # Для Devise требуется подтверждение
        )
        puts "✨ УСПЕХ: Создан новый AdminUser:"
        puts "Email: #{admin.email}"
        puts "Пароль: #{password}"
      end
    else
      puts "⚠️ ПРЕДУПРЕЖДЕНИЕ: Модель AdminUser не найдена. Убедитесь, что Active Admin настроен правильно."
    end
  end
end
