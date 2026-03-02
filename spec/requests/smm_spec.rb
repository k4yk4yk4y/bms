require "rails_helper"

RSpec.describe "SMM section", type: :request do
  let!(:project) { create(:project, name: "SMM Project") }

  describe "authentication" do
    it "redirects guests to sign in" do
      get smm_months_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "as smm manager" do
    let(:smm_manager) { create(:user, role: :smm_manager) }
    let!(:month) { create(:smm_month, starts_on: Date.new(2026, 3, 1), name: "March 2026") }

    before { sign_in smm_manager, scope: :user }

    it "creates SMM month" do
      expect {
        post smm_months_path, params: { smm_month: { name: "April 2026", month: "2026-04" } }
      }.to change(SmmMonth, :count).by(1)

      expect(response).to redirect_to(smm_months_path(month_id: SmmMonth.last.id))
    end

    it "adds project to month" do
      expect {
        post smm_month_smm_month_projects_path(month), params: { smm_month_project: { project_id: project.id } }
      }.to change(SmmMonthProject, :count).by(1)

      month_project = SmmMonthProject.order(:id).last
      expect(response).to redirect_to(smm_months_path(month_id: month.id, month_project_id: month_project.id))
    end

    it "returns bonuses for selected month project" do
      month_project = create(:smm_month_project, smm_month: month, project: project)
      matching = create(:bonus, project: project.name, code: "SMM_MATCH_2026", name: "SMM Matching Bonus")
      create(:bonus, project: "Other Project", code: "SMM_OTHER_2026", name: "SMM Other Bonus")

      get bonuses_smm_month_smm_month_project_path(month, month_project), params: { q: "MATCH" }

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      ids = payload.map { |item| item.fetch("id") }

      expect(ids).to contain_exactly(matching.id)
    end

    it "creates bonuses in batch from preset" do
      month_project = create(:smm_month_project, smm_month: month, project: project)
      preset = create(:smm_preset, project: project, manager: smm_manager)

      expect {
        post batch_create_smm_month_smm_bonuses_path(month),
             params: {
               smm_month_project_id: month_project.id,
               smm_preset_id: preset.id,
               rows: [
                 { code: "ROW_CODE_1", game: "book_of_dead", fs_count: "20", deposit: "100" },
                 { code: "ROW_CODE_2", game: "sweet_bonanza", fs_count: "30", deposit: "200" }
               ]
             }
      }.to change(SmmBonus, :count).by(2)

      expect(response).to redirect_to(smm_months_path(month_id: month.id, month_project_id: month_project.id))
    end
  end

  context "as support agent" do
    let(:support_agent) { create(:user, role: :support_agent) }

    before { sign_in support_agent, scope: :user }

    it "cannot create SMM month" do
      expect {
        post smm_months_path, params: { smm_month: { name: "Blocked", month: "2026-05" } }
      }.not_to change(SmmMonth, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
