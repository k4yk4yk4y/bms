require 'rails_helper'

RSpec.describe 'User filters bonuses by project', type: :request do
  let(:user) { create(:user) }
  let(:project1) { create(:project, name: 'VOLNA') }
  let(:project2) { create(:project, name: 'ROX') }
  let!(:bonus1) { create(:bonus, project: project1.name) }
  let!(:bonus2) { create(:bonus, project: project2.name) }

  before do
    sign_in user
  end

  describe 'GET /bonuses with project_id filter' do
    it 'returns only bonuses for the selected project' do
      get bonuses_path, params: { project_id: project1.id }

      expect(response).to have_http_status(:success)
      expect(response.body).to include(bonus1.name)
      expect(response.body).not_to include(bonus2.name)
    end

    it 'returns all bonuses when no project filter is applied' do
      get bonuses_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(bonus1.name)
      expect(response.body).to include(bonus2.name)
    end

    it 'displays project filter dropdown' do
      get bonuses_path

      expect(response.body).to include('VOLNA')
      expect(response.body).to include('ROX')
    end
  end
end
