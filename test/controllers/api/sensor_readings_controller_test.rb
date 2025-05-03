require "test_helper"

class Api::SensorReadingsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_sensor_readings_create_url
    assert_response :success
  end
end
