require "application_system_test_case"

class BonusTemplatesTest < ApplicationSystemTestCase
  setup do
    @admin_user = create(:admin_user)
    sign_in @admin_user
    @dsl_tag = create(:dsl_tag, name: "VIP")
    @project = create(:project, name: "Casino A")
    @bonus_template = create(
      :bonus_template,
      name: "Welcome Bonus",
      dsl_tag: @dsl_tag.name,
      project: @project.name,
      minimum_deposit: 100,
      wager: 30
    )
  end

  test "should display created bonus template on admin index" do
    visit admin_bonus_templates_url

    assert_text "Welcome Bonus"
    assert_text "VIP"
    assert_text "Casino A"
  end
end
