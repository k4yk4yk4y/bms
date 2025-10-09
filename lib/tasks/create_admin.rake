namespace :admin do
  desc "Create admin user for production"
  task create: :environment do
    email = ENV['ADMIN_EMAIL'] || 'admin@bms.com'
    password = ENV['ADMIN_PASSWORD'] || 'password123'
    first_name = ENV['ADMIN_FIRST_NAME'] || 'Admin'
    last_name = ENV['ADMIN_LAST_NAME'] || 'User'

    if User.exists?(email: email)
      puts "Admin user with email #{email} already exists!"
      user = User.find_by(email: email)
      puts "Email: #{user.email}"
      puts "Role: #{user.display_role}"
      puts "Full name: #{user.full_name}"
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: first_name,
        last_name: last_name,
        role: :admin
      )

      puts "Admin user created successfully!"
      puts "Email: #{user.email}"
      puts "Password: #{password}"
      puts "Role: #{user.display_role}"
      puts "Full name: #{user.full_name}"
    end
  end

  desc "Create admin user with custom credentials"
  task :create_custom, [:email, :password, :first_name, :last_name] => :environment do |t, args|
    email = args[:email] || ENV['ADMIN_EMAIL'] || 'admin@bms.com'
    password = args[:password] || ENV['ADMIN_PASSWORD'] || 'password123'
    first_name = args[:first_name] || ENV['ADMIN_FIRST_NAME'] || 'Admin'
    last_name = args[:last_name] || ENV['ADMIN_LAST_NAME'] || 'User'

    if User.exists?(email: email)
      puts "Admin user with email #{email} already exists!"
      user = User.find_by(email: email)
      puts "Email: #{user.email}"
      puts "Role: #{user.display_role}"
      puts "Full name: #{user.full_name}"
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: first_name,
        last_name: last_name,
        role: :admin
      )

      puts "Admin user created successfully!"
      puts "Email: #{user.email}"
      puts "Password: #{password}"
      puts "Role: #{user.display_role}"
      puts "Full name: #{user.full_name}"
    end
  end
end
