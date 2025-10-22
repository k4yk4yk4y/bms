require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  setup do
    @admin_user = create(:admin_user)
    sign_in @admin_user
    @project1 = create(:project, name: "Project Alpha")
    @project2 = create(:project, name: "Project Beta")
    create(:bonus, name: "Bonus for Alpha", project: @project1)
    create(:bonus, name: "Bonus for Beta", project: @project2)
  end

  test "should filter bonuses by project from navigation dropdown" do
    visit admin_bonuses_url

    # Check if the project dropdown exists in the navigation
    assert_selector "nav", text: "Projects" # Assuming navigation element

    # Select Project Alpha from the dropdown
    within("nav") do # Assuming the dropdown is within the nav element
      click_on "Projects" # Click to open dropdown if needed
      click_on @project1.name # Click on the project name in the dropdown
    end

    # Verify that the page is filtered for Project Alpha
    assert_current_path admin_bonuses_path(project_id: @project1.id)
    assert_text "Bonus for Alpha"
    refute_text "Bonus for Beta"
  end
end
