require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get marketing_index_url
    assert_response :success
  end

  test "should get show" do
    get marketing_show_url
    assert_response :success
  end

  test "should get new" do
    get marketing_new_url
    assert_response :success
  end

  test "should get create" do
    get marketing_create_url
    assert_response :success
  end

  test "should get edit" do
    get marketing_edit_url
    assert_response :success
  end

  test "should get update" do
    get marketing_update_url
    assert_response :success
  end

  test "should get destroy" do
    get marketing_destroy_url
    assert_response :success
  end
end
