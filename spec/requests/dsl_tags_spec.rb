require 'rails_helper'

RSpec.describe "DslTags", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:dsl_tag) { create(:dsl_tag) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/dsl_tags" do
    it "returns http success" do
      get admin_dsl_tags_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/dsl_tags/:id" do
    it "returns http success" do
      get admin_dsl_tag_path(dsl_tag)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/dsl_tags/new" do
    it "returns http success" do
      get new_admin_dsl_tag_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/dsl_tags" do
    context "with valid parameters" do
      let(:valid_attributes) { { name: "New DSL Tag", description: "New description" } }

      it "creates a new DslTag" do
        expect {
          post admin_dsl_tags_path, params: { dsl_tag: valid_attributes }
        }.to change(DslTag, :count).by(1)
      end

      it "redirects to the created dsl_tag" do
        post admin_dsl_tags_path, params: { dsl_tag: valid_attributes }
        expect(response).to redirect_to(admin_dsl_tag_path(DslTag.last))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "", description: "Description" } }

      it "does not create a new DslTag" do
        expect {
          post admin_dsl_tags_path, params: { dsl_tag: invalid_attributes }
        }.not_to change(DslTag, :count)
      end
    end
  end

  describe "PATCH /admin/dsl_tags/:id" do
    let(:new_attributes) { { name: "Updated DSL Tag", description: "Updated description" } }

    it "updates the requested dsl_tag" do
      patch admin_dsl_tag_path(dsl_tag), params: { dsl_tag: new_attributes }
      dsl_tag.reload
      expect(dsl_tag.name).to eq("Updated DSL Tag")
      expect(dsl_tag.description).to eq("Updated description")
    end

    it "redirects to the dsl_tag" do
      patch admin_dsl_tag_path(dsl_tag), params: { dsl_tag: new_attributes }
      expect(response).to redirect_to(admin_dsl_tag_path(dsl_tag))
    end
  end

  describe "DELETE /admin/dsl_tags/:id" do
    context "when dsl_tag has no bonuses" do
      let!(:dsl_tag_without_bonuses) { create(:dsl_tag) }

      before do
        # Ensure no bonuses are associated with this dsl_tag
        Bonus.where(dsl_tag_id: dsl_tag_without_bonuses.id).update_all(dsl_tag_id: nil)
      end

      it "destroys the requested dsl_tag" do
        expect {
          delete admin_dsl_tag_path(dsl_tag_without_bonuses)
        }.to change(DslTag, :count).by(-1)
      end

      it "redirects to the dsl_tags list" do
        delete admin_dsl_tag_path(dsl_tag_without_bonuses)
        expect(response).to redirect_to(admin_dsl_tags_path)
      end
    end

    context "when dsl_tag has bonuses" do
      let!(:bonus) { create(:bonus, dsl_tag_id: dsl_tag.id) }

      it "does not destroy the dsl_tag" do
        expect {
          delete admin_dsl_tag_path(dsl_tag)
        }.not_to change(DslTag, :count)
      end

      it "redirects with an alert" do
        delete admin_dsl_tag_path(dsl_tag)
        expect(response).to redirect_to(admin_dsl_tags_path)
        expect(flash[:alert]).to include("используется в бонусах")
      end
    end
  end
end
