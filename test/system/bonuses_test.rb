require "application_system_test_case"

class BonusesTest < ApplicationSystemTestCase
  setup do
    @admin_user = create(:admin_user)
    sign_in @admin_user
    @dsl_tag1 = create(:dsl_tag, name: "Tag 1")
    @dsl_tag2 = create(:dsl_tag, name: "Tag 2")
  end

  test "should select dsl_tag from dropdown when creating a bonus" do
    visit new_admin_bonus_url

    assert_selector "select#bonus_dsl_tag_id"
    assert_selector "select#bonus_dsl_tag_id option", text: @dsl_tag1.name
    assert_selector "select#bonus_dsl_tag_id option", text: @dsl_tag2.name

    select @dsl_tag1.name, from: "bonus_dsl_tag_id"
    assert_equal @dsl_tag1.id.to_s, find("select#bonus_dsl_tag_id").value
  end

  test "should list created bonuses on index page" do
    create(:bonus, name: "Bonus A", dsl_tag: @dsl_tag1)
    create(:bonus, name: "Bonus B", dsl_tag: @dsl_tag2)
    visit admin_bonuses_url

    assert_text "Bonus A"
    assert_text "Bonus B"
  end
end
