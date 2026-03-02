require "rails_helper"

RSpec.describe "Project section (ActiveAdmin)", type: :request do
  describe "access control" do
    it "redirects regular users to admin login" do
      sign_in create(:user, role: :admin), scope: :user

      get admin_projects_path

      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it "redirects guests to admin login" do
      get admin_projects_path

      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  context "as admin user" do
    let(:admin_user) { create(:admin_user) }

    before { sign_in(admin_user, scope: :admin_user) }

    it "shows project index" do
      project = create(:project, name: "Project Main")

      get admin_projects_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name)
    end

    it "creates project" do
      expect {
        post admin_projects_path, params: { project: { name: "New Project CI", currencies: "USD;EUR" } }
      }.to change(Project, :count).by(1)

      created = Project.order(:id).last
      expect(response).to redirect_to(admin_project_path(created))
      expect(created.currencies).to contain_exactly("USD", "EUR")
    end

    it "updates project" do
      project = create(:project, name: "Old Project", currencies: [ "USD" ])

      patch admin_project_path(project), params: { project: { name: "Updated Project", currencies: "EUR;BTC" } }

      expect(response).to redirect_to(admin_project_path(project))
      project.reload
      expect(project.name).to eq("Updated Project")
      expect(project.currencies).to contain_exactly("EUR", "BTC")
    end

    it "deletes project" do
      project = create(:project)

      expect {
        delete admin_project_path(project)
      }.to change(Project, :count).by(-1)

      expect(response).to redirect_to(admin_projects_path)
    end
  end
end
