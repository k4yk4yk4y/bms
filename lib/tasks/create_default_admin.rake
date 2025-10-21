namespace :admin do
  desc "Create default admin users for deployment"
  task create_defaults: :environment do
    puts "=== Creating Default Admin Users ==="
    
    # Create main admin user
    admin_email = ENV["ADMIN_EMAIL"] || "admin@bms.com"
    admin_password = ENV["ADMIN_PASSWORD"] || "password123"
    
    if User.exists?(email: admin_email)
      puts "Admin user with email #{admin_email} already exists!"
    else
      admin = User.create!(
        email: admin_email,
        password: admin_password,
        password_confirmation: admin_password,
        first_name: "Super",
        last_name: "Admin",
        role: :admin
      )
      puts "✅ Main admin user created successfully!"
      puts "   Email: #{admin.email}"
      puts "   Password: #{admin_password}"
    end
    
    # Create AdminUser for ActiveAdmin
    admin_user_email = ENV["ADMIN_USER_EMAIL"] || "admin@example.com"
    admin_user_password = ENV["ADMIN_USER_PASSWORD"] || "password"
    
    if AdminUser.exists?(email: admin_user_email)
      puts "AdminUser with email #{admin_user_email} already exists!"
    else
      admin_user = AdminUser.create!(
        email: admin_user_email,
        password: admin_user_password,
        password_confirmation: admin_user_password
      )
      puts "✅ AdminUser for ActiveAdmin created successfully!"
      puts "   Email: #{admin_user.email}"
      puts "   Password: #{admin_user_password}"
    end
    
    puts "\n=== Login Credentials ==="
    puts "Main Admin Panel:"
    puts "  Email: #{admin_email}"
    puts "  Password: #{admin_password}"
    puts "\nActiveAdmin Panel:"
    puts "  Email: #{admin_user_email}"
    puts "  Password: #{admin_user_password}"
  end
end
