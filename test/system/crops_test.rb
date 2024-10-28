require "application_system_test_case"

class CropsTest < ApplicationSystemTestCase
  setup do
    @crop = crops(:one)
  end

  test "visiting the index" do
    visit crops_url
    assert_selector "h1", text: "Crops"
  end

  test "should create crop" do
    visit crops_url
    click_on "New crop"

    fill_in "Expected harvest", with: @crop.expected_harvest
    fill_in "Name", with: @crop.name
    fill_in "Notes", with: @crop.notes
    fill_in "Planted on", with: @crop.planted_on
    click_on "Create Crop"

    assert_text "Crop was successfully created"
    click_on "Back"
  end

  test "should update Crop" do
    visit crop_url(@crop)
    click_on "Edit this crop", match: :first

    fill_in "Expected harvest", with: @crop.expected_harvest
    fill_in "Name", with: @crop.name
    fill_in "Notes", with: @crop.notes
    fill_in "Planted on", with: @crop.planted_on
    click_on "Update Crop"

    assert_text "Crop was successfully updated"
    click_on "Back"
  end

  test "should destroy Crop" do
    visit crop_url(@crop)
    click_on "Destroy this crop", match: :first

    assert_text "Crop was successfully destroyed"
  end
end
