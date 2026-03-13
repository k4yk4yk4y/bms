require "application_system_test_case"

class DslTagsTest < ApplicationSystemTestCase
  setup do
    @admin_user = create(:admin_user)
    sign_in @admin_user
    @dsl_tag = create(:dsl_tag, name: "Original DSL Tag")
  end

  test "visiting the index" do
    visit admin_dsl_tags_url
    assert_current_path admin_dsl_tags_path
    assert_text @dsl_tag.name
  end

  test "creating a Dsl tag" do
    visit new_admin_dsl_tag_url
    assert_field "Name"
    assert_field "Description"
  end

  test "updating a Dsl tag" do
    visit edit_admin_dsl_tag_url(@dsl_tag)

    fill_in "Name", with: "Updated DSL Tag"
    fill_in "Description", with: "Updated description"
    click_on "Update Dsl tag"

    @dsl_tag.reload
    assert_equal "Updated DSL Tag", @dsl_tag.name
  end

  test "destroying a Dsl tag" do
    visit admin_dsl_tags_url
    assert_selector :css, "a[href='#{admin_dsl_tag_path(@dsl_tag)}'][data-method='delete'], a[href='#{admin_dsl_tag_path(@dsl_tag)}'][data-turbo-method='delete']"
  end
end
