require "rails_helper"

RSpec.describe "Bonuses section", type: :request do
  let!(:volna_project) { create(:project, name: "VOLNA") }
  let!(:jet_project) { create(:project, name: "JET") }
  let!(:dsl_tag) { create(:dsl_tag) }
  let!(:volna_bonus) do
    create(
      :bonus,
      name: "Volna Bonus",
      code: "VOLNA_BONUS_MAIN",
      project: volna_project.name,
      dsl_tag: dsl_tag
    )
  end
  let!(:jet_bonus) { create(:bonus, name: "Jet Bonus", code: "JET_BONUS_MAIN", project: jet_project.name) }

  describe "authentication" do
    it "redirects guests to sign in" do
      get bonuses_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    let(:admin) { create(:user, role: :admin) }

    before { sign_in admin, scope: :user }

    it "returns project-filtered bonuses in JSON" do
      get bonuses_path(format: :json), params: { project_id: volna_project.id }

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      ids = payload.map { |item| item.fetch("id") }

      expect(ids).to include(volna_bonus.id)
      expect(ids).not_to include(jet_bonus.id)
    end

    it "creates a bonus" do
      attributes = attributes_for(:bonus, name: "Created Bonus", code: "CREATED_BONUS_2026", project: volna_project.name)

      expect {
        post bonuses_path, params: { bonus: attributes }
      }.to change(Bonus, :count).by(1)

      expect(response).to redirect_to(bonus_path(Bonus.last))
    end

    it "duplicates a bonus to draft" do
      expect {
        post duplicate_bonus_path(volna_bonus)
      }.to change(Bonus, :count).by(1)

      duplicated = Bonus.order(:id).last
      expect(duplicated.status).to eq("draft")
      expect(duplicated.code).to start_with("#{volna_bonus.code}_COPY")
      expect(response).to redirect_to(edit_bonus_path(duplicated))
    end
  end

  describe "as support agent" do
    let(:support_agent) { create(:user, role: :support_agent) }

    before { sign_in support_agent, scope: :user }

    it "cannot create bonuses" do
      attributes = attributes_for(:bonus, name: "Forbidden Bonus", code: "FORBIDDEN_BONUS_2026", project: volna_project.name)

      expect {
        post bonuses_path, params: { bonus: attributes }
      }.not_to change(Bonus, :count)

      expect(response).to redirect_to(marketing_index_path)
    end

    it "cannot duplicate bonuses" do
      expect {
        post duplicate_bonus_path(volna_bonus)
      }.not_to change(Bonus, :count)

      expect(response).to redirect_to(marketing_index_path)
    end
  end
end
