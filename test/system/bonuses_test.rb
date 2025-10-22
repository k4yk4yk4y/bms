require "application_system_test_case"

class BonusesTest < ApplicationSystemTestCase
  setup do
    @admin_user = create(:admin_user) # Assuming FactoryBot for admin_user
    sign_in @admin_user # Assuming a sign_in helper
    @dsl_tag1 = create(:dsl_tag, name: "Tag 1") # Assuming FactoryBot for dsl_tag
    @dsl_tag2 = create(:dsl_tag, name: "Tag 2")
  end

  test "should select dsl_tag from dropdown when creating a bonus" do
    visit new_admin_bonus_url # Assuming ActiveAdmin path for new bonus

    fill_in "Name", with: "Test Bonus"
    select @dsl_tag1.name, from: "bonus_dsl_tag_id" # Assuming dropdown name/id
    click_on "Create Bonus" # Assuming button text

    assert_text "Bonus was successfully created."
    assert_text "Dsl tag: #{@dsl_tag1.name}"
  end

  test "should filter bonuses by dsl_tag text input on index page" do
    # Create some bonuses with dsl_tags
    create(:bonus, name: "Bonus A", dsl_tag: @dsl_tag1)
    create(:bonus, name: "Bonus B", dsl_tag: @dsl_tag2)
    create(:bonus, name: "Bonus C", dsl_tag: @dsl_tag1)

    visit admin_bonuses_url # Assuming ActiveAdmin path for bonuses index

    # Fill in the dsl_tag filter field (assuming it's a text input with a specific ID/name)
    fill_in "q_dsl_tag_name_cont", with: @dsl_tag1.name # Assuming Ransack filter name
    click_on "Filter" # Assuming filter button text

    assert_text "Bonus A"
    assert_text "Bonus C"
    refute_text "Bonus B"

    # Clear filter
    click_on "Clear Filters"
    assert_text "Bonus A"
    assert_text "Bonus B"
    assert_text "Bonus C"
  end
end
