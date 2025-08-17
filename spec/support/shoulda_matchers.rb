# frozen_string_literal: true

# Configure Shoulda Matchers for Rails testing
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
