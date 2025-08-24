# spec/support/authentication_helpers.rb

module AuthenticationHelpers
  # Create and sign in a user for controller specs
  def sign_in_user(user = nil, role: :admin)
    user ||= create(:user, role: role)
    sign_in user, scope: :user
    user
  end

  # Create and sign in an admin user for controller specs
  def sign_in_admin_user(admin_user = nil)
    admin_user ||= create(:admin_user)
    sign_in admin_user, scope: :admin_user
    admin_user
  end

  # Login user for request specs
  def login_as(user, scope: :user)
    login_as(user, scope: scope)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :request
end
