require "rails_helper"

RSpec.describe "Role permissions", type: :request do
  let!(:bonus) { create(:bonus) }
  let!(:marketing_request) { create(:marketing_request, :complete_valid_request) }
  let!(:project) { create(:project) }
  let!(:retention_chain) { RetentionChain.create!(status: "draft") }
  let!(:retention_email) { RetentionEmail.create!(retention_chain: retention_chain, status: "draft") }
  let!(:bonus_template) { create(:bonus_template) }

  def json_headers
    { "ACCEPT" => "application/json" }
  end

  context "as support agent (read-only by default)" do
    let(:user) { create(:user, role: :support_agent) }

    before do
      login_as(user, scope: :user)
    end

    it "allows reading bonuses but blocks write actions" do
      get bonuses_path
      expect(response).to have_http_status(:success)

      get bonus_path(bonus)
      expect(response).to have_http_status(:success)

      get new_bonus_path
      expect(response).to have_http_status(:redirect)

      get edit_bonus_path(bonus)
      expect(response).to have_http_status(:redirect)

      expect {
        post bonuses_path, params: { bonus: attributes_for(:bonus) }
      }.not_to change(Bonus, :count)

      expect {
        patch bonus_path(bonus), params: { bonus: { name: "Updated" } }
      }.not_to change { bonus.reload.name }

      expect {
        delete bonus_path(bonus)
      }.not_to change(Bonus, :count)
    end

    it "blocks bonus duplication and bulk updates" do
      expect {
        post duplicate_bonus_path(bonus)
      }.not_to change(Bonus, :count)

      expect {
        post bulk_update_bonuses_path, params: { bulk_action: "duplicate", bonus_ids: [ bonus.id ] }
      }.not_to change(Bonus, :count)
    end

    it "allows reading marketing requests but blocks write actions" do
      get marketing_index_path
      expect(response).to have_http_status(:success)

      get marketing_path(marketing_request)
      expect(response).to have_http_status(:success)

      get new_marketing_path
      expect(response).to have_http_status(:redirect)

      get edit_marketing_path(marketing_request)
      expect(response).to have_http_status(:redirect)

      expect {
        post marketing_index_path, params: { marketing_request: attributes_for(:marketing_request, :complete_valid_request) }
      }.not_to change(MarketingRequest, :count)

      expect {
        patch marketing_path(marketing_request), params: { marketing_request: { promo_code: "NEWCODE123" } }
      }.not_to change { marketing_request.reload.promo_code }

      expect {
        patch activate_marketing_path(marketing_request)
      }.not_to change { marketing_request.reload.status }

      expect {
        patch reject_marketing_path(marketing_request)
      }.not_to change { marketing_request.reload.status }

      expect {
        patch transfer_marketing_path(marketing_request), params: { new_request_type: MarketingRequest::REQUEST_TYPES.first }
      }.not_to change { marketing_request.reload.request_type }

      expect {
        delete marketing_path(marketing_request)
      }.not_to change(MarketingRequest, :count)
    end

    it "allows reading retention chains but blocks write actions" do
      get retention_chains_path
      expect(response).to have_http_status(:success)

      get retention_chain_path(retention_chain)
      expect(response).to have_http_status(:success)

      get new_retention_chain_path
      expect(response).to have_http_status(:redirect)

      get edit_retention_chain_path(retention_chain)
      expect(response).to have_http_status(:redirect)

      expect {
        post retention_chains_path, params: { retention_chain: { status: "draft" } }
      }.not_to change(RetentionChain, :count)

      expect {
        patch retention_chain_path(retention_chain), params: { retention_chain: { name: "Updated" } }
      }.not_to change { retention_chain.reload.name }

      expect {
        delete retention_chain_path(retention_chain)
      }.not_to change(RetentionChain, :count)
    end

    it "allows reading retention emails but blocks write actions" do
      get retention_chain_retention_email_path(retention_chain, retention_email)
      expect(response).to have_http_status(:success)

      get new_retention_chain_retention_email_path(retention_chain)
      expect(response).to have_http_status(:redirect)

      get edit_retention_chain_retention_email_path(retention_chain, retention_email)
      expect(response).to have_http_status(:redirect)

      expect {
        post retention_chain_retention_emails_path(retention_chain), params: { retention_email: { status: "draft" } }
      }.not_to change(RetentionEmail, :count)

      expect {
        patch retention_chain_retention_email_path(retention_chain, retention_email),
              params: { retention_email: { subject: "Updated" } }
      }.not_to change { retention_email.reload.subject }

      expect {
        delete retention_chain_retention_email_path(retention_chain, retention_email)
      }.not_to change(RetentionEmail, :count)
    end

    it "denies access to settings and API sections" do
      get settings_templates_path
      expect(response).to have_http_status(:redirect)

      get api_v1_bonuses_path, headers: json_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "allows heatmap but blocks heatmap comments" do
      get heatmap_path
      expect(response).to have_http_status(:success)

      get heatmap_comments_path
      expect(response).to have_http_status(:redirect)
    end
  end

  context "as delivery manager (read-only bonuses, heatmap, retention, projects, and profiles)" do
    let(:user) { create(:user, role: :delivery_manager) }
    let(:other_user) { create(:user) }

    before do
      login_as(user, scope: :user)
    end

    it "allows read access to requested sections and profiles" do
      get bonuses_path
      expect(response).to have_http_status(:success)

      get bonuses_path, params: { project_id: project.id }
      expect(response).to have_http_status(:success)

      get heatmap_path
      expect(response).to have_http_status(:success)

      get retention_chains_path
      expect(response).to have_http_status(:success)

      get user_path(user)
      expect(response).to have_http_status(:success)

      get user_path(other_user)
      expect(response).to have_http_status(:success)
    end

    it "blocks write actions" do
      get new_bonus_path
      expect(response).to have_http_status(:redirect)

      expect {
        post bonuses_path, params: { bonus: attributes_for(:bonus) }
      }.not_to change(Bonus, :count)

      get new_retention_chain_path
      expect(response).to have_http_status(:redirect)

      expect {
        post retention_chains_path, params: { retention_chain: { status: "draft" } }
      }.not_to change(RetentionChain, :count)
    end
  end

  context "as marketing manager without permanent bonuses permission" do
    let(:user) { create(:user, role: :marketing_manager) }

    before do
      login_as(user, scope: :user)
    end

    it "blocks access to /bonuses entirely" do
      get bonuses_path
      expect(response).to redirect_to(marketing_index_path)
    end
  end

  context "as marketing manager with permanent-only bonuses access" do
    let(:user) { create(:user, role: :marketing_manager) }
    let(:permanent_project) { create(:project, name: "PERM_ONLY") }
    let!(:permanent_bonus) { create(:bonus, project: permanent_project.name) }
    let!(:regular_bonus) { create(:bonus, project: permanent_project.name) }
    let!(:permanent_link) { create(:permanent_bonus, project: permanent_project, bonus: permanent_bonus) }

    before do
      role = Role.find_or_initialize_by(key: "marketing_manager")
      role.name = role.name.presence || "Marketing Manager"
      role.permissions = Role.default_permissions_for("marketing_manager").merge(
        "bonuses" => "none",
        "projects" => "read",
        "permanent_bonuses" => "read"
      )
      role.save!

      login_as(user, scope: :user)
    end

    it "shows only permanent bonuses and redirects on non-permanent bonus pages" do
      get bonuses_path, params: { project_id: permanent_project.id }
      expect(response).to have_http_status(:success)
      expect(response.body).to include(permanent_bonus.name)
      expect(response.body).not_to include(regular_bonus.name)

      get bonus_path(permanent_bonus)
      expect(response).to have_http_status(:success)

      get bonus_path(regular_bonus), params: { project_id: permanent_project.id }
      expect(response).to redirect_to(bonuses_path(project_id: permanent_project.id))

      follow_redirect!
      expect(response.body).to include("Недостаточно прав для вашей роли")
    end
  end

  context "when role permissions are customized" do
    let(:user) { create(:user, role: :support_agent) }

    before do
      role = Role.find_or_initialize_by(key: "support_agent")
      role.name = role.name.presence || "Support Agent"
      role.permissions = {
        "bonuses" => "write",
        "permanent_bonuses" => "read",
        "projects" => "read"
      }
      role.save!
      login_as(user, scope: :user)
    end

    it "respects updated permissions for write access" do
      patch bonus_path(bonus), params: { bonus: { name: "Permission Update" } }
      expect(response).to redirect_to(bonus_path(bonus))
      expect(bonus.reload.name).to eq("Permission Update")
    end
  end
end
