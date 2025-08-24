require 'rails_helper'

RSpec.describe "Settings", type: :request do
  # Sign in a user for all tests since SettingsController requires authentication
  before do
    @user = create(:user, role: :admin)
    # Используем Warden напрямую для request specs
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  describe "GET /templates" do
    it "returns http success" do
      get "/settings/templates"
      expect(response).to have_http_status(:success)
    end
  end
end
