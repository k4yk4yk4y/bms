require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "protected routes" do
    it "redirects unauthenticated users to the login page" do
      get bonuses_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "user session redirects" do
    it "redirects marketing manager to marketing section after sign in" do
      user = create(:user, role: :marketing_manager, password: "password123", password_confirmation: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(marketing_index_path)
    end

    it "redirects retention manager to retention section after sign in" do
      user = create(:user, role: :retention_manager, password: "password123", password_confirmation: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(retention_chains_path)
    end

    it "redirects smm manager to smm section after sign in" do
      user = create(:user, role: :smm_manager, password: "password123", password_confirmation: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(smm_months_path)
    end

    it "redirects admin user to bonuses section after sign in" do
      user = create(:user, role: :admin, password: "password123", password_confirmation: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(bonuses_path)
    end

    it "redirects support agent user to bonuses section after sign in" do
      user = create(:user, role: :support_agent, password: "password123", password_confirmation: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(bonuses_path)
    end

    it "redirects delivery manager user to bonuses section after sign in" do
      user = create(:user, role: :delivery_manager, password: "password123", password_confirmation: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(bonuses_path)
    end

    it "redirects to user login after sign out" do
      user = create(:user, role: :admin)
      sign_in user, scope: :user

      delete destroy_user_session_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "admin session redirects" do
    it "redirects admin user to ActiveAdmin root after sign in" do
      admin_user = create(:admin_user, password: "password", password_confirmation: "password")

      post admin_user_session_path, params: { admin_user: { email: admin_user.email, password: "password" } }

      expect(response).to redirect_to(admin_root_path)
    end
  end
end
