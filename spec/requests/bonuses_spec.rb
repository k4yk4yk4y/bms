require 'rails_helper'

RSpec.describe "Bonuses", type: :request do
  # Sign in a user for all tests since BonusesController requires authentication
  before do
    @user = create(:user, role: :admin)
    # Используем Warden напрямую для request specs
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  describe "GET /bonuses/new" do
    context "when template_id is provided" do
      let(:template) { create(:bonus_template, :welcome_bonus) }

      it "shows the form page" do
        get new_bonus_path(template_id: template.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("New Bonus")
      end
    end

    context "when no template_id is provided" do
      it "shows empty form" do
        get new_bonus_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("New Bonus")
      end
    end
  end
end
