require "test_helper"

class HeatmapControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get heatmap_index_url
    assert_response :success
  end
end
