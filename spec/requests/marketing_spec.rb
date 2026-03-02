require "rails_helper"

RSpec.describe "Marketing section", type: :request do
  describe "authentication" do
    it "redirects guests to sign in" do
      get marketing_index_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "as marketing manager" do
    let(:marketing_manager) { create(:user, role: :marketing_manager, email: "manager@example.com") }
    let!(:own_request) do
      create(
        :marketing_request,
        manager: marketing_manager.email,
        promo_code: "OWNCODE2026",
        stag: "OWNSTAG2026",
        request_type: "promo_webs_50"
      )
    end
    let!(:other_request) do
      create(
        :marketing_request,
        manager: "another_manager@example.com",
        promo_code: "OTHERCODE2026",
        stag: "OTHERSTAG2026",
        request_type: "promo_webs_50"
      )
    end

    before { sign_in marketing_manager, scope: :user }

    it "shows only manager-owned requests" do
      get marketing_index_path, params: { tab: "promo_webs_50" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("OWNCODE2026")
      expect(response.body).not_to include("OTHERCODE2026")
    end

    it "creates request with current user as manager" do
      params = {
        marketing_request: {
          manager: "spoofed@example.com",
          platform: "example.com",
          partner_email: "partner@example.com",
          promo_code: "NEWCODE2026",
          stag: "NEWSTAG2026",
          request_type: "promo_webs_100"
        }
      }

      expect {
        post marketing_index_path, params: params
      }.to change(MarketingRequest, :count).by(1)

      created = MarketingRequest.order(:id).last
      expect(created.manager).to eq(marketing_manager.email)
      expect(created.promo_code).to eq("NEWCODE2026")
      expect(response).to redirect_to(marketing_index_path(tab: "promo_webs_100"))
    end

    it "transfers request to another tab and resets status" do
      own_request.update!(status: "activated", activation_date: Time.current)

      patch transfer_marketing_path(own_request), params: { new_request_type: "promo_webs_100" }

      expect(response).to redirect_to(marketing_index_path(tab: "promo_webs_100"))
      own_request.reload
      expect(own_request.request_type).to eq("promo_webs_100")
      expect(own_request.status).to eq("pending")
      expect(own_request.activation_date).to be_nil
    end
  end

  context "as support agent" do
    let(:support_agent) { create(:user, role: :support_agent) }

    before { sign_in support_agent, scope: :user }

    it "cannot create requests" do
      expect {
        post marketing_index_path,
             params: {
               marketing_request: {
                 platform: "example.com",
                 partner_email: "partner@example.com",
                 promo_code: "BLOCKEDCODE2026",
                 stag: "BLOCKEDSTAG2026",
                 request_type: "promo_webs_50"
               }
             }
      }.not_to change(MarketingRequest, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
