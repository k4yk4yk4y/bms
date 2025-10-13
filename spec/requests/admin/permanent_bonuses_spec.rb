require 'rails_helper'

RSpec.describe "Admin::PermanentBonuses", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:bonus) { create(:bonus) }
  let(:project) { create(:project, name: 'Test Project') }
  let!(:permanent_bonus) { create(:permanent_bonus, bonus: bonus, project: project) }

  before do
    sign_in(admin_user, scope: :admin_user)
  end

  describe "GET /admin/permanent_bonuses" do
    it "returns a successful response" do
      get admin_permanent_bonuses_path
      expect(response).to be_successful
    end

    it "displays the project name" do
      get admin_permanent_bonuses_path
      expect(response.body).to include('Test Project')
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

    it "displays project selection" do
      get new_admin_permanent_bonus_path
      expect(response.body).to include('Project')
    end
  end

  describe "POST /admin/permanent_bonuses" do
    let(:new_bonus) { create(:bonus) }
    let(:new_project) { create(:project, name: 'New Project') }
    let(:valid_attributes) { { permanent_bonus: { project_id: new_project.id, bonus_id: new_bonus.id } } }

    it "creates a new PermanentBonus" do
      expect {
        post admin_permanent_bonuses_path, params: valid_attributes
      }.to change(PermanentBonus, :count).by(1)
    end

    it "associates the bonus with the selected project" do
      post admin_permanent_bonuses_path, params: valid_attributes
      permanent_bonus = PermanentBonus.last
      expect(permanent_bonus.project).to eq(new_project)
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
