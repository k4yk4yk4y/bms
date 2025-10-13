require 'rails_helper'

RSpec.describe "Admin::PermanentBonuses", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:bonus) { create(:bonus) }
  let!(:permanent_bonus) { create(:permanent_bonus, bonus: bonus, project: 'Test Project') }

  before do
    sign_in(admin_user, scope: :admin_user)
  end

  describe "GET /admin/permanent_bonuses" do
    it "returns a successful response" do
      get admin_permanent_bonuses_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/permanent_bonuses/:id" do
    it "returns a successful response" do
      get admin_permanent_bonus_path(permanent_bonus)
      expect(response).to be_successful
    end
  end

  describe "GET /admin/permanent_bonuses/new" do
    it "returns a successful response" do
      get new_admin_permanent_bonus_path
      expect(response).to be_successful
    end
  end

  describe "POST /admin/permanent_bonuses" do
    let(:new_bonus) { create(:bonus) }
    let(:valid_attributes) { { permanent_bonus: { project: 'New Project', bonus_id: new_bonus.id } } }

    it "creates a new PermanentBonus" do
      expect {
        post admin_permanent_bonuses_path, params: valid_attributes
      }.to change(PermanentBonus, :count).by(1)
    end
  end

  describe "DELETE /admin/permanent_bonuses/:id" do
    it "destroys the requested permanent_bonus" do
      expect {
        delete admin_permanent_bonus_path(permanent_bonus)
      }.to change(PermanentBonus, :count).by(-1)
    end
  end
end
