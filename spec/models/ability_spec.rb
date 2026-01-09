require "rails_helper"

RSpec.describe Ability do
  describe "frontend roles" do
    it "allows self profile access based on self_profile permission" do
      Role.create!(
        key: "support_agent",
        name: "Support Agent",
        permissions: { "users" => "none", "self_profile" => "read" }
      )

      user = create(:user, role: :support_agent)
      other_user = create(:user)
      ability = described_class.new(user)

      expect(ability.can?(:read, user)).to be(true)
      expect(ability.can?(:update, user)).to be(false)
      expect(ability.can?(:read, other_user)).to be(false)
    end

    it "maps write permission to create/update without destroy" do
      Role.create!(
        key: "promo_manager",
        name: "Promo Manager",
        permissions: { "bonuses" => "write" }
      )

      user = create(:user, role: :promo_manager)
      ability = described_class.new(user)

      expect(ability.can?(:read, Bonus)).to be(true)
      expect(ability.can?(:create, Bonus)).to be(true)
      expect(ability.can?(:update, Bonus)).to be(true)
      expect(ability.can?(:destroy, Bonus)).to be(false)
    end
  end

  describe "admin roles" do
    it "scopes ActiveAdmin access by admin role permissions" do
      admin_role = create(:admin_role, permissions: { "bonuses" => "read", "admin_users" => "none" })
      admin_user = create(:admin_user, admin_role: admin_role)
      ability = described_class.new(admin_user)

      expect(ability.can?(:read, Bonus)).to be(true)
      expect(ability.can?(:manage, Bonus)).to be(false)
      expect(ability.can?(:read, AdminUser)).to be(false)
    end
  end
end
