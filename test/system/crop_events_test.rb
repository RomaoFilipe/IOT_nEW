require "application_system_test_case"

class CropEventsTest < ApplicationSystemTestCase
  setup do
    @crop_event = crop_events(:one)
  end

  test "visiting the index" do
    visit crop_events_url
    assert_selector "h1", text: "Crop events"
  end

  test "should create crop event" do
    visit crop_events_url
    click_on "New crop event"

    fill_in "Description", with: @crop_event.description
    fill_in "End time", with: @crop_event.end_time
    fill_in "Event type", with: @crop_event.event_type
    fill_in "Name", with: @crop_event.name
    fill_in "Start time", with: @crop_event.start_time
    click_on "Create Crop event"

    assert_text "Crop event was successfully created"
    click_on "Back"
  end

  test "should update Crop event" do
    visit crop_event_url(@crop_event)
    click_on "Edit this crop event", match: :first

    fill_in "Description", with: @crop_event.description
    fill_in "End time", with: @crop_event.end_time.to_s
    fill_in "Event type", with: @crop_event.event_type
    fill_in "Name", with: @crop_event.name
    fill_in "Start time", with: @crop_event.start_time.to_s
    click_on "Update Crop event"

    assert_text "Crop event was successfully updated"
    click_on "Back"
  end

  test "should destroy Crop event" do
    visit crop_event_url(@crop_event)
    click_on "Destroy this crop event", match: :first

    assert_text "Crop event was successfully destroyed"
  end
end
