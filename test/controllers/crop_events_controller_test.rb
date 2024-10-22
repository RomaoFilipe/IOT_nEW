require "test_helper"

class CropEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @crop_event = crop_events(:one)
  end

  test "should get index" do
    get crop_events_url
    assert_response :success
  end

  test "should get new" do
    get new_crop_event_url
    assert_response :success
  end

  test "should create crop_event" do
    assert_difference("CropEvent.count") do
      post crop_events_url, params: { crop_event: { description: @crop_event.description, end_time: @crop_event.end_time, event_type: @crop_event.event_type, name: @crop_event.name, start_time: @crop_event.start_time } }
    end

    assert_redirected_to crop_event_url(CropEvent.last)
  end

  test "should show crop_event" do
    get crop_event_url(@crop_event)
    assert_response :success
  end

  test "should get edit" do
    get edit_crop_event_url(@crop_event)
    assert_response :success
  end

  test "should update crop_event" do
    patch crop_event_url(@crop_event), params: { crop_event: { description: @crop_event.description, end_time: @crop_event.end_time, event_type: @crop_event.event_type, name: @crop_event.name, start_time: @crop_event.start_time } }
    assert_redirected_to crop_event_url(@crop_event)
  end

  test "should destroy crop_event" do
    assert_difference("CropEvent.count", -1) do
      delete crop_event_url(@crop_event)
    end

    assert_redirected_to crop_events_url
  end
end
