require "application_system_test_case"

class DslTagsTest < ApplicationSystemTestCase
  setup do
    @admin_user = admin_users(:one)
    @dsl_tag = dsl_tags(:one)
  end

  test "visiting the index" do
    visit admin_dsl_tags_url
    assert_selector "h1", text: "Dsl Tags"
  end

  test "creating a Dsl tag" do
    visit admin_dsl_tags_url
    click_on "New Dsl Tag"

    fill_in "Name", with: "Test DSL Tag"
    fill_in "Description", with: "Test description"
    click_on "Create Dsl tag"

    assert_text "Dsl tag was successfully created"
    click_on "Back"
  end

  test "updating a Dsl tag" do
    visit admin_dsl_tags_url
    click_on "Edit", match: :first

    fill_in "Name", with: "Updated DSL Tag"
    fill_in "Description", with: "Updated description"
    click_on "Update Dsl tag"

    assert_text "Dsl tag was successfully updated"
    click_on "Back"
  end

  test "destroying a Dsl tag" do
    visit admin_dsl_tags_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Dsl tag was successfully destroyed"
  end
end
