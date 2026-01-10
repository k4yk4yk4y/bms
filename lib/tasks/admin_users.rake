namespace :admin do
  desc "Creates default admin users for main app and ActiveAdmin"
  task create_default: :environment do
    email = "p.rusakevich@jetmail.cc"
    password = "612891123Pasha"

    if User.exists?(email: email)
      puts "✅ Пользователь с email '#{email}' уже существует. Пропускаем создание."
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: "Admin",
        last_name: "User",
        role: :admin
      )
      puts "✨ УСПЕХ: Создан новый пользователь приложения:"
      puts "Email: #{user.email}"
      puts "Пароль: #{password}"
      puts "Роль: #{user.display_role}"
    end

    unless defined?(AdminUser)
      puts "⚠️ ПРЕДУПРЕЖДЕНИЕ: Модель AdminUser не найдена. Убедитесь, что Active Admin настроен правильно."
      return
    end

    admin_role = AdminRole.find_or_create_by!(key: "superadmin") do |role|
      role.name = "Superadmin"
      role.permissions = AdminRole.section_keys.index_with { "manage" }
    end

    if AdminUser.find_by(email: email)
      puts "✅ Администратор ActiveAdmin с email '#{email}' уже существует. Пропускаем создание."
    else
      admin = AdminUser.create!(
        email: email,
        password: password,
        password_confirmation: password,
        admin_role: admin_role
      )
      puts "✨ УСПЕХ: Создан новый AdminUser:"
      puts "Email: #{admin.email}"
      puts "Пароль: #{password}"
    end
  end
end
