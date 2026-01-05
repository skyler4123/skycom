require "test_helper"

class PricePeriodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @price_period = price_periods(:one)
  end

  test "should get index" do
    get price_periods_url
    assert_response :success
  end

  test "should get new" do
    get new_price_period_url
    assert_response :success
  end

  test "should create price_period" do
    assert_difference("PricePeriod.count") do
      post price_periods_url, params: { price_period: { period_id: @price_period.period_id, price_id: @price_period.price_id, price_periodable_id: @price_period.price_periodable_id, price_periodable_type: @price_period.price_periodable_type } }
    end

    assert_redirected_to price_period_url(PricePeriod.last)
  end

  test "should show price_period" do
    get price_period_url(@price_period)
    assert_response :success
  end

  test "should get edit" do
    get edit_price_period_url(@price_period)
    assert_response :success
  end

  test "should update price_period" do
    patch price_period_url(@price_period), params: { price_period: { period_id: @price_period.period_id, price_id: @price_period.price_id, price_periodable_id: @price_period.price_periodable_id, price_periodable_type: @price_period.price_periodable_type } }
    assert_redirected_to price_period_url(@price_period)
  end

  test "should destroy price_period" do
    assert_difference("PricePeriod.count", -1) do
      delete price_period_url(@price_period)
    end

    assert_redirected_to price_periods_url
  end
end
