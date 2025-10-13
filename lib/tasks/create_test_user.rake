namespace :users do
  desc "Create a test user with support agent role"
  task create_test_user: :environment do
    email = "support@example.com"
    password = "password123"

    if User.exists?(email: email)
      puts "User with email #{email} already exists!"
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: "Support",
        last_name: "Agent",
        role: :support_agent
      )

      puts "Test user created successfully!"
      puts "Email: #{email}"
      puts "Password: #{password}"
      puts "Role: #{user.display_role}"
    end
  end

  desc "Create a test admin user for testing"
  task create_test_admin: :environment do
    email = "admin@test.com"
    password = "123456"

    if User.exists?(email: email)
      puts "Admin user with email #{email} already exists!"
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: "Test",
        last_name: "Admin",
        role: :admin
      )

      puts "Test admin user created successfully!"
      puts "Email: #{email}"
      puts "Password: #{password}"
      puts "Role: #{user.display_role}"
    end
  end
end
