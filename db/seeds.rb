# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create default admin user if none exists
if User.where(role: :admin).empty?
  admin = User.create!(
    email: 'admin@bms.com',
    password: 'password123',
    password_confirmation: 'password123',
    role: :admin,
    first_name: 'Super',
    last_name: 'Admin'
  )
  puts "Created admin user: #{admin.email}"
end

# Create sample users for each role if they don't exist
roles = {
  promo_manager: { email: 'promo@bms.com', first_name: 'Promo', last_name: 'Manager' },
  shift_leader: { email: 'shift@bms.com', first_name: 'Shift', last_name: 'Leader' },
  support_agent: { email: 'support@bms.com', first_name: 'Support', last_name: 'Agent' }
}

roles.each do |role, attrs|
  unless User.where(role: role).exists?
    user = User.create!(
      email: attrs[:email],
      password: 'password123',
      password_confirmation: 'password123',
      role: role,
      first_name: attrs[:first_name],
      last_name: attrs[:last_name]
    )
    puts "Created #{role} user: #{user.email}"
  end
end

puts "Database seeding completed!"
puts "Admin login: admin@bms.com / password123"
puts "Available roles:"
User.roles.keys.each do |role|
  user = User.find_by(role: role)
  puts "- #{role.humanize}: #{user&.email || 'Not created'}"
end