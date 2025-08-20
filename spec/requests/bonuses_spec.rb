require 'rails_helper'

RSpec.describe "Bonuses", type: :request do
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
