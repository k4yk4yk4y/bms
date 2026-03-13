require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, :admin_role)
    sign_in @user
    @project1 = create(:project, name: "Project Alpha")
    @project2 = create(:project, name: "Project Beta")
    create(:bonus, name: "Bonus for Alpha", project: @project1.name)
    create(:bonus, name: "Bonus for Beta", project: @project2.name)
  end

  test "should filter bonuses by project from navigation dropdown" do
    visit bonuses_url(project_id: @project1.id)

    assert_text "PROJECTS"
    assert_current_path bonuses_path(project_id: @project1.id)
    assert_text "Bonus for Alpha"
    refute_text "Bonus for Beta"
  end
end
