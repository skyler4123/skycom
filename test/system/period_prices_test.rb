require "application_system_test_case"

class PeriodPricesTest < ApplicationSystemTestCase
  setup do
    @period_price = period_prices(:one)
  end

  test "visiting the index" do
    visit period_prices_url
    assert_selector "h1", text: "Period prices"
  end

  test "should create period price" do
    visit period_prices_url
    click_on "New period price"

    fill_in "Period", with: @period_price.period_id
    fill_in "Period priceable", with: @period_price.period_priceable_id
    fill_in "Period priceable type", with: @period_price.period_priceable_type
    fill_in "Price", with: @period_price.price_id
    click_on "Create Period price"

    assert_text "Period price was successfully created"
    click_on "Back"
  end

  test "should update Period price" do
    visit period_price_url(@period_price)
    click_on "Edit this period price", match: :first

    fill_in "Period", with: @period_price.period_id
    fill_in "Period priceable", with: @period_price.period_priceable_id
    fill_in "Period priceable type", with: @period_price.period_priceable_type
    fill_in "Price", with: @period_price.price_id
    click_on "Update Period price"

    assert_text "Period price was successfully updated"
    click_on "Back"
  end

  test "should destroy Period price" do
    visit period_price_url(@period_price)
    accept_confirm { click_on "Destroy this period price", match: :first }

    assert_text "Period price was successfully destroyed"
  end
end
