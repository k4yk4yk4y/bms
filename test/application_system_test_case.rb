require "test_helper"
require "warden/test/helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Warden::Test::Helpers

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    Warden.test_mode!
  end

  teardown do
    Warden.test_reset!
  end

  def sign_in(user)
    scope = user.is_a?(AdminUser) ? :admin_user : :user
    login_as(user, scope: scope)
  end
end
