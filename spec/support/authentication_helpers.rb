# spec/support/authentication_helpers.rb

module AuthenticationHelpers
  # Create and sign in a user for controller specs
  def sign_in_user(user = nil, role: :admin)
    user ||= create(:user, role: role)
    # В тестах отключаем аутентификацию полностью
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
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
    # Для request specs используем sign_in
    sign_in user, scope: scope
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :request
end
