require "test_helper"

class SubscriptionGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription_group = subscription_groups(:one)
  end

  test "should get index" do
    get subscription_groups_url
    assert_response :success
  end

  test "should get new" do
    get new_subscription_group_url
    assert_response :success
  end

  test "should create subscription_group" do
    assert_difference("SubscriptionGroup.count") do
      post subscription_groups_url, params: { subscription_group: { auto_renew: @subscription_group.auto_renew, business_type: @subscription_group.business_type, code: @subscription_group.code, country_code: @subscription_group.country_code, description: @subscription_group.description, discarded_at: @subscription_group.discarded_at, lifecycle_status: @subscription_group.lifecycle_status, name: @subscription_group.name, period_id: @subscription_group.period_id, price_id: @subscription_group.price_id, workflow_status: @subscription_group.workflow_status } }
    end

    assert_redirected_to subscription_group_url(SubscriptionGroup.last)
  end

  test "should show subscription_group" do
    get subscription_group_url(@subscription_group)
    assert_response :success
  end

  test "should get edit" do
    get edit_subscription_group_url(@subscription_group)
    assert_response :success
  end

  test "should update subscription_group" do
    patch subscription_group_url(@subscription_group), params: { subscription_group: { auto_renew: @subscription_group.auto_renew, business_type: @subscription_group.business_type, code: @subscription_group.code, country_code: @subscription_group.country_code, description: @subscription_group.description, discarded_at: @subscription_group.discarded_at, lifecycle_status: @subscription_group.lifecycle_status, name: @subscription_group.name, period_id: @subscription_group.period_id, price_id: @subscription_group.price_id, workflow_status: @subscription_group.workflow_status } }
    assert_redirected_to subscription_group_url(@subscription_group)
  end

  test "should destroy subscription_group" do
    assert_difference("SubscriptionGroup.count", -1) do
      delete subscription_group_url(@subscription_group)
    end

    assert_redirected_to subscription_groups_url
  end
end
