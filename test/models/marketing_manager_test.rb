# frozen_string_literal: true

require "test_helper"

# Тесты для проверки функциональности роли marketing_manager
class MarketingManagerTest < ActiveSupport::TestCase
  def setup
    @marketing_manager = User.create!(
      email: "marketing_manager@test.com",
      password: "password123",
      first_name: "Marketing",
      last_name: "Manager",
      role: :marketing_manager
    )

    @admin = User.create!(
      email: "admin@test.com",
      password: "password123",
      first_name: "Admin",
      last_name: "User",
      role: :admin
    )

    @support_agent = User.create!(
      email: "support@test.com",
      password: "password123",
      first_name: "Support",
      last_name: "Agent",
      role: :support_agent
    )
  end

  test "marketing_manager role is properly assigned" do
    assert @marketing_manager.marketing_manager?
    assert_equal "marketing_manager", @marketing_manager.role
    assert_equal "Marketing manager", @marketing_manager.display_role
  end

  test "marketing_manager scope works correctly" do
    marketing_managers = User.marketing_managers
    assert_includes marketing_managers, @marketing_manager
    refute_includes marketing_managers, @admin
    refute_includes marketing_managers, @support_agent
  end

  test "marketing_manager can view marketing" do
    assert @marketing_manager.can_view_marketing?
  end

  test "marketing_manager can manage marketing" do
    assert @marketing_manager.can_manage_marketing?
  end

  test "marketing_manager cannot manage bonuses" do
    refute @marketing_manager.can_manage_bonuses?
  end

  test "marketing_manager cannot access support" do
    refute @marketing_manager.can_access_support?
  end

  test "marketing_manager cannot access admin" do
    refute @marketing_manager.can_access_admin?
  end

  test "marketing_manager has correct permissions in ability" do
    ability = Ability.new(@marketing_manager)

    # Should have access to marketing
    assert ability.can?(:manage, MarketingRequest)
    assert ability.can?(:read, ActiveAdmin::Page, name: "Dashboard")
    assert ability.can?(:read, User, id: @marketing_manager.id)
    assert ability.can?(:update, User, id: @marketing_manager.id)

    # Should NOT have access to bonuses
    refute ability.can?(:manage, Bonus)
    refute ability.can?(:read, Bonus)
    refute ability.can?(:create, Bonus)
    refute ability.can?(:update, Bonus)
    refute ability.can?(:destroy, Bonus)

    # Should NOT have access to bonus templates
    refute ability.can?(:manage, BonusTemplate)
    refute ability.can?(:read, BonusTemplate)

    # Should NOT have access to settings
    refute ability.can?(:access, :settings)
    refute ability.can?(:manage, :settings)

    # Should NOT have access to API
    refute ability.can?(:access, :api)
    refute ability.can?(:manage, :api)
  end



  test "marketing_manager enum value is correct" do
    assert_equal 4, User.roles[:marketing_manager]
  end

  test "marketing_manager can perform all marketing request actions" do
    ability = Ability.new(@marketing_manager)

    # Создаем заявку, принадлежащую этому менеджеру
    marketing_request = MarketingRequest.new(manager: @marketing_manager.email)

    assert ability.can?(:create, marketing_request)
    assert ability.can?(:read, marketing_request)
    assert ability.can?(:update, marketing_request)
    assert ability.can?(:destroy, marketing_request)
    assert ability.can?(:activate, marketing_request)
    assert ability.can?(:reject, marketing_request)
    assert ability.can?(:transfer, marketing_request)
  end

  test "marketing_manager cannot access other managers' marketing requests" do
    ability = Ability.new(@marketing_manager)

    # Создаем заявку другого менеджера
    other_marketing_request = MarketingRequest.new(manager: "other_manager@test.com")

    # Marketing manager НЕ должен иметь доступ к чужим заявкам
    refute ability.can?(:read, other_marketing_request)
    refute ability.can?(:update, other_marketing_request)
    refute ability.can?(:destroy, other_marketing_request)
    refute ability.can?(:activate, other_marketing_request)
    refute ability.can?(:reject, other_marketing_request)
    refute ability.can?(:transfer, other_marketing_request)
  end

  test "marketing_manager is included in can_view_marketing users" do
    users_who_can_view = User.all.select(&:can_view_marketing?)
    assert_includes users_who_can_view, @marketing_manager
  end

  test "marketing_manager is included in can_manage_marketing users" do
    users_who_can_manage = User.all.select(&:can_manage_marketing?)
    assert_includes users_who_can_manage, @marketing_manager
  end

  test "marketing_manager full_name works correctly" do
    assert_equal "Marketing Manager", @marketing_manager.full_name
  end

  test "marketing_manager has correct ransackable attributes" do
    ransackable = User.ransackable_attributes
    expected_attributes = [
      "created_at", "email", "first_name", "id", "last_name",
      "remember_created_at", "reset_password_sent_at", "role", "updated_at"
    ]

    expected_attributes.each do |attr|
      assert_includes ransackable, attr
    end
  end

  test "default role is not marketing_manager" do
    new_user = User.new(email: "new@test.com")
    new_user.valid? # trigger callbacks

    refute_equal "marketing_manager", new_user.role
    assert_equal "support_agent", new_user.role
  end
end
