require "test_helper"

class PeriodPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @period_price = period_prices(:one)
  end

  test "should get index" do
    get period_prices_url
    assert_response :success
  end

  test "should get new" do
    get new_period_price_url
    assert_response :success
  end

  test "should create period_price" do
    assert_difference("PeriodPrice.count") do
      post period_prices_url, params: { period_price: { period_id: @period_price.period_id, period_priceable_id: @period_price.period_priceable_id, period_priceable_type: @period_price.period_priceable_type, price_id: @period_price.price_id } }
    end

    assert_redirected_to period_price_url(PeriodPrice.last)
  end

  test "should show period_price" do
    get period_price_url(@period_price)
    assert_response :success
  end

  test "should get edit" do
    get edit_period_price_url(@period_price)
    assert_response :success
  end

  test "should update period_price" do
    patch period_price_url(@period_price), params: { period_price: { period_id: @period_price.period_id, period_priceable_id: @period_price.period_priceable_id, period_priceable_type: @period_price.period_priceable_type, price_id: @period_price.price_id } }
    assert_redirected_to period_price_url(@period_price)
  end

  test "should destroy period_price" do
    assert_difference("PeriodPrice.count", -1) do
      delete period_price_url(@period_price)
    end

    assert_redirected_to period_prices_url
  end
end
