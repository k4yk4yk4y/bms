require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get marketing_index_url
    assert_response :success
  end

  test "should get show" do
    marketing_request = marketing_requests(:one)
    get marketing_url(marketing_request)
    assert_response :success
  end

  test "should get new" do
    get new_marketing_url
    assert_response :success
  end

  test "should get create" do
    post marketing_index_url, params: { marketing_request: {
      manager: "Test Manager",
      partner_email: "test@example.com",
      promo_code: "TEST123",
      stag: "test_stag_unique",
      request_type: "promo_webs_50"
    } }
    assert_response :redirect
  end

  test "should get edit" do
    marketing_request = marketing_requests(:one)
    get edit_marketing_url(marketing_request)
    assert_response :success
  end

  test "should get update" do
    marketing_request = marketing_requests(:one)
    patch marketing_url(marketing_request), params: { marketing_request: {
      manager: "Updated Manager"
    } }
    assert_response :redirect
  end

  test "should get destroy" do
    marketing_request = marketing_requests(:one)
    delete marketing_url(marketing_request)
    assert_response :redirect
  end
end
