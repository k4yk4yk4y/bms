require 'rails_helper'

RSpec.describe "Settings::BonusTemplates", type: :request do
  # Sign in a user for all tests since BonusTemplatesController requires authentication
  before do
    @user = create(:user, role: :admin)
    # Используем Warden напрямую для request specs
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  describe "GET /settings/templates" do
    it "displays the templates index page" do
      get settings_templates_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Bonus Templates")
    end
  end

  describe "GET /settings/templates/new" do
    it "displays the new template form" do
      get new_settings_template_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Bonus Template")
    end
  end

  describe "POST /settings/templates" do
    let(:valid_attributes) do
      {
        name: "Test Template",
        dsl_tag: "test_tag",
        project: "VOLNA",
        event: "deposit",
        currencies: [ "USD" ],
        currency_minimum_deposits: { "USD" => 10.0 },
        wager: 35.0,
        maximum_winnings: 500.0
      }
    end

    it "creates a new template" do
      expect {
        post settings_templates_path, params: { bonus_template: valid_attributes }
      }.to change(BonusTemplate, :count).by(1)

      expect(response).to redirect_to(settings_templates_path)
      follow_redirect!
      expect(response.body).to include("Шаблон бонуса успешно создан")
    end

    it "renders new template form with errors for invalid attributes" do
      invalid_attributes = valid_attributes.merge(name: "")

      expect {
        post settings_templates_path, params: { bonus_template: invalid_attributes }
      }.not_to change(BonusTemplate, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("New Bonus Template")
    end
  end

  describe "GET /settings/templates/:id" do
    let(:template) { create(:bonus_template) }

    it "displays the template details" do
      get settings_template_path(template)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(template.name)
      expect(response.body).to include(template.dsl_tag)
    end
  end

  describe "GET /settings/templates/:id/edit" do
    let(:template) { create(:bonus_template) }

    it "displays the edit template form" do
      get edit_settings_template_path(template)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Bonus Template")
      expect(response.body).to include(template.name)
    end
  end

  describe "PATCH /settings/templates/:id" do
    let(:template) { create(:bonus_template) }
    let(:new_attributes) { { name: "Updated Template Name" } }

    it "updates the template" do
      patch settings_template_path(template), params: { bonus_template: new_attributes }

      expect(response).to redirect_to(settings_templates_path)
      follow_redirect!
      expect(response.body).to include("Шаблон бонуса успешно обновлен")

      template.reload
      expect(template.name).to eq("Updated Template Name")
    end

    it "renders edit template form with errors for invalid attributes" do
      invalid_attributes = { name: "" }

      patch settings_template_path(template), params: { bonus_template: invalid_attributes }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Edit Bonus Template")
    end
  end

  describe "DELETE /settings/templates/:id" do
    let!(:template) { create(:bonus_template) }

    it "deletes the template" do
      expect {
        delete settings_template_path(template)
      }.to change(BonusTemplate, :count).by(-1)

      expect(response).to redirect_to(settings_templates_path)
      follow_redirect!
      expect(response.body).to include("Шаблон бонуса успешно удален")
    end
  end
end
