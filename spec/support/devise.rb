# spec/support/devise.rb

# Include Devise Test Helpers for controller specs
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers

  config.before :each do
    Warden.test_mode!
  end

  config.after :each do
    Warden.test_reset!
  end
end
