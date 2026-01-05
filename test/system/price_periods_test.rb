require "application_system_test_case"

class PricePeriodsTest < ApplicationSystemTestCase
  setup do
    @price_period = price_periods(:one)
  end

  test "visiting the index" do
    visit price_periods_url
    assert_selector "h1", text: "Price periods"
  end

  test "should create price period" do
    visit price_periods_url
    click_on "New price period"

    fill_in "Period", with: @price_period.period_id
    fill_in "Price", with: @price_period.price_id
    fill_in "Price periodable", with: @price_period.price_periodable_id
    fill_in "Price periodable type", with: @price_period.price_periodable_type
    click_on "Create Price period"

    assert_text "Price period was successfully created"
    click_on "Back"
  end

  test "should update Price period" do
    visit price_period_url(@price_period)
    click_on "Edit this price period", match: :first

    fill_in "Period", with: @price_period.period_id
    fill_in "Price", with: @price_period.price_id
    fill_in "Price periodable", with: @price_period.price_periodable_id
    fill_in "Price periodable type", with: @price_period.price_periodable_type
    click_on "Update Price period"

    assert_text "Price period was successfully updated"
    click_on "Back"
  end

  test "should destroy Price period" do
    visit price_period_url(@price_period)
    accept_confirm { click_on "Destroy this price period", match: :first }

    assert_text "Price period was successfully destroyed"
  end
end
