require "application_system_test_case"

class BonusTemplatesTest < ApplicationSystemTestCase
  setup do
    @admin_user = create(:admin_user)
    sign_in @admin_user
    @dsl_tag = create(:dsl_tag, name: "VIP")
    @project = create(:project, name: "Casino A")
    @bonus_template = create(:bonus_template,
                             name: "Welcome Bonus",
                             dsl_tag: @dsl_tag.name, # Assuming dsl_tag is stored as string in template
                             project: @project.name, # Assuming project is stored as string in template
                             minimum_deposit: 100,
                             wager: 30)
  end

  test "should pre-fill bonus form from template when dsl_tag and project match" do
    visit new_admin_bonus_url # Assuming ActiveAdmin path for new bonus

    fill_in "Name", with: @bonus_template.name
    select @dsl_tag.name, from: "bonus_dsl_tag_id" # Assuming dropdown name/id
    select @project.name, from: "bonus_project_id" # Assuming dropdown name/id for project

    # Trigger the Stimulus controller to fetch template data (if it's not automatic)
    # This might require a specific action, e.g., blurring a field or clicking a button
    # For now, assume it's automatic or triggered by field changes.

    assert_field "Minimum deposit", with: @bonus_template.minimum_deposit
    assert_field "Wager", with: @bonus_template.wager
  end
end
