require "rails_helper"

RSpec.describe "Heatmap section", type: :request do
  let!(:deposit_bonus) do
    create(
      :bonus,
      name: "Deposit Heatmap Bonus",
      code: "HEATMAP_DEPOSIT_2026",
      event: "deposit",
      availability_start_date: Time.zone.local(2026, 1, 10, 10, 0, 0),
      availability_end_date: Time.zone.local(2026, 1, 31, 23, 0, 0)
    )
  end

  let!(:manual_bonus) do
    create(
      :bonus,
      :manual_event,
      name: "Manual Heatmap Bonus",
      code: "HEATMAP_MANUAL_2026",
      availability_start_date: Time.zone.local(2026, 1, 15, 10, 0, 0),
      availability_end_date: Time.zone.local(2026, 1, 31, 23, 0, 0)
    )
  end

  it "redirects guests to sign in" do
    get heatmap_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as support agent" do
    let(:support_agent) { create(:user, role: :support_agent) }

    before { sign_in support_agent, scope: :user }

    it "opens heatmap successfully" do
      get heatmap_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bonus Heatmap")
    end

    it "accepts filtering by event and shows event badge" do
      get heatmap_path, params: { year: 2026, month: 1, bonus_event: "deposit" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Deposit")
      expect(response.body).not_to include("Manual Heatmap Bonus")
    end

    it "falls back to safe defaults for invalid params" do
      get heatmap_path, params: { year: 99999, month: 99, bonus_event: "invalid_event" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bonus Heatmap")
    end
  end

  context "as marketing manager" do
    let(:marketing_manager) { create(:user, role: :marketing_manager) }

    before { sign_in marketing_manager, scope: :user }

    it "denies access" do
      get heatmap_path

      expect(response).to redirect_to(root_path)
    end
  end
end
