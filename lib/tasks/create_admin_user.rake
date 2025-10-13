namespace :admin_user do
  desc "Create admin user for admin panel"
  task create: :environment do
    email = ENV["ADMIN_USER_EMAIL"] || "admin@example.com"
    password = ENV["ADMIN_USER_PASSWORD"] || "password"

    if AdminUser.exists?(email: email)
      puts "Admin user with email #{email} already exists!"
      admin_user = AdminUser.find_by(email: email)
      puts "Email: #{admin_user.email}"
    else
      admin_user = AdminUser.create!(
        email: email,
        password: password,
        password_confirmation: password
      )

      puts "Admin user for admin panel created successfully!"
      puts "Email: #{admin_user.email}"
      puts "Password: #{password}"
    end
  end

  desc "Create admin user with custom credentials"
  task :create_custom, [ :email, :password ] => :environment do |t, args|
    email = args[:email] || ENV["ADMIN_USER_EMAIL"] || "admin@example.com"
    password = args[:password] || ENV["ADMIN_USER_PASSWORD"] || "password"

    if AdminUser.exists?(email: email)
      puts "Admin user with email #{email} already exists!"
      admin_user = AdminUser.find_by(email: email)
      puts "Email: #{admin_user.email}"
    else
      admin_user = AdminUser.create!(
        email: email,
        password: password,
        password_confirmation: password
      )

      puts "Admin user for admin panel created successfully!"
      puts "Email: #{admin_user.email}"
      puts "Password: #{password}"
    end
  end
end
