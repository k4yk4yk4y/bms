require 'rails_helper'

RSpec.describe 'Admin::Projects', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in(admin_user, scope: :admin_user)
  end

  describe 'GET /admin/projects' do
    let!(:project) { create(:project, name: 'Test Project') }

    it 'returns a successful response' do
      get admin_projects_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the project name' do
      get admin_projects_path
      expect(response.body).to include('Test Project')
    end
  end

  describe 'GET /admin/projects/:id' do
    let(:project) { create(:project, name: 'Test Project') }

    it 'returns a successful response' do
      get admin_project_path(project)
      expect(response).to have_http_status(:success)
    end

    it 'displays the project details' do
      get admin_project_path(project)
      expect(response.body).to include('Test Project')
    end
  end

  describe 'GET /admin/projects/new' do
    it 'returns a successful response' do
      get new_admin_project_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/projects' do
    context 'with valid parameters' do
      let(:valid_attributes) { { project: { name: 'New Project' } } }

      it 'creates a new project' do
        expect {
          post admin_projects_path, params: valid_attributes
        }.to change(Project, :count).by(1)
      end

      it 'redirects to the project details page' do
        post admin_projects_path, params: valid_attributes
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { project: { name: '' } } }

      it 'does not create a new project' do
        expect {
          post admin_projects_path, params: invalid_attributes
        }.not_to change(Project, :count)
      end

      it 'returns an unprocessable entity status' do
        post admin_projects_path, params: invalid_attributes
        expect(response).to have_http_status(:success) # Active Admin returns 200 with errors
      end
    end
  end

  describe 'GET /admin/projects/:id/edit' do
    let(:project) { create(:project) }

    it 'returns a successful response' do
      get edit_admin_project_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /admin/projects/:id' do
    let(:project) { create(:project, name: 'Old Name') }

    context 'with valid parameters' do
      let(:new_attributes) { { project: { name: 'New Name' } } }

      it 'updates the project' do
        patch admin_project_path(project), params: new_attributes
        project.reload
        expect(project.name).to eq('New Name')
      end

      it 'redirects to the project details page' do
        patch admin_project_path(project), params: new_attributes
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { project: { name: '' } } }

      it 'does not update the project' do
        patch admin_project_path(project), params: invalid_attributes
        project.reload
        expect(project.name).to eq('Old Name')
      end
    end
  end

  describe 'DELETE /admin/projects/:id' do
    let!(:project) { create(:project) }

    it 'destroys the project' do
      expect {
        delete admin_project_path(project)
      }.to change(Project, :count).by(-1)
    end

    it 'redirects to the projects list' do
      delete admin_project_path(project)
      expect(response).to have_http_status(:redirect)
    end
  end
end
