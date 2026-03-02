require "rails_helper"

RSpec.describe "Retention section", type: :request do
  let!(:project) { create(:project, name: "Retention Project") }

  describe "authentication" do
    it "redirects guests to sign in" do
      get retention_chains_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "as retention manager" do
    let(:retention_manager) { create(:user, role: :retention_manager) }
    let!(:chain) { create(:retention_chain, project: project, status: "draft") }

    before { sign_in retention_manager, scope: :user }

    it "creates a retention chain" do
      params = {
        retention_chain: {
          name: "Welcome Flow",
          project_id: project.id,
          status: "draft"
        }
      }

      expect {
        post retention_chains_path, params: params
      }.to change(RetentionChain, :count).by(1)

      expect(response).to redirect_to(edit_retention_chain_path(RetentionChain.last))
    end

    it "creates retention email in chain" do
      params = {
        retention_email: {
          subject: "Come back",
          header: "We miss you",
          body: "Retention body",
          status: "active"
        }
      }

      expect {
        post retention_chain_retention_emails_path(chain), params: params
      }.to change(RetentionEmail, :count).by(1)

      created = RetentionEmail.order(:id).last
      expect(response).to redirect_to(retention_chain_retention_email_path(chain, created))
    end

    it "returns project bonuses for autocomplete" do
      matching = create(:bonus, project: project.name, code: "RET_MATCH_2026", name: "Retention Match")
      create(:bonus, project: "Other Project", code: "RET_OTHER_2026", name: "Other Bonus")

      get bonuses_retention_chain_path(chain), params: { q: "Match" }

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      ids = payload.map { |item| item.fetch("id") }

      expect(ids).to contain_exactly(matching.id)
    end

    it "reorders chain emails" do
      email_one = create(:retention_email, retention_chain: chain)
      email_two = create(:retention_email, retention_chain: chain)

      patch reorder_retention_chain_retention_emails_path(chain), params: { order: [ email_two.id, email_one.id ] }

      expect(response).to have_http_status(:ok)
      expect(email_two.reload.position).to eq(1)
      expect(email_one.reload.position).to eq(2)
    end
  end

  context "as support agent" do
    let(:support_agent) { create(:user, role: :support_agent) }

    before { sign_in support_agent, scope: :user }

    it "cannot create retention chains" do
      expect {
        post retention_chains_path,
             params: {
               retention_chain: {
                 name: "Blocked chain",
                 project_id: project.id,
                 status: "draft"
               }
             }
      }.not_to change(RetentionChain, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
