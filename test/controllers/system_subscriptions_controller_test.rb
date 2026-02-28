require "test_helper"

class SystemSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_subscription = system_subscriptions(:one)
  end

  test "should get index" do
    get system_subscriptions_url
    assert_response :success
  end

  test "should get new" do
    get new_system_subscription_url
    assert_response :success
  end

  test "should create system_subscription" do
    assert_difference("SystemSubscription.count") do
      post system_subscriptions_url, params: { system_subscription: { auto_renew: @system_subscription.auto_renew, business_type: @system_subscription.business_type, code: @system_subscription.code, company_id: @system_subscription.company_id, branch_id: @system_subscription.branch_id, country_code: @system_subscription.country_code, description: @system_subscription.description, discarded_at: @system_subscription.discarded_at, lifecycle_status: @system_subscription.lifecycle_status, name: @system_subscription.name, period_id: @system_subscription.period_id, price_id: @system_subscription.price_id, subscription_group_id: @system_subscription.subscription_group_id, system_subscription_plan_id: @system_subscription.system_subscription_plan_id, workflow_status: @system_subscription.workflow_status } }
    end

    assert_redirected_to system_subscription_url(SystemSubscription.last)
  end

  test "should show system_subscription" do
    get system_subscription_url(@system_subscription)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_subscription_url(@system_subscription)
    assert_response :success
  end

  test "should update system_subscription" do
    patch system_subscription_url(@system_subscription), params: { system_subscription: { auto_renew: @system_subscription.auto_renew, business_type: @system_subscription.business_type, code: @system_subscription.code, company_id: @system_subscription.company_id, branch_id: @system_subscription.branch_id, country_code: @system_subscription.country_code, description: @system_subscription.description, discarded_at: @system_subscription.discarded_at, lifecycle_status: @system_subscription.lifecycle_status, name: @system_subscription.name, period_id: @system_subscription.period_id, price_id: @system_subscription.price_id, subscription_group_id: @system_subscription.subscription_group_id, system_subscription_plan_id: @system_subscription.system_subscription_plan_id, workflow_status: @system_subscription.workflow_status } }
    assert_redirected_to system_subscription_url(@system_subscription)
  end

  test "should destroy system_subscription" do
    assert_difference("SystemSubscription.count", -1) do
      delete system_subscription_url(@system_subscription)
    end

    assert_redirected_to system_subscriptions_url
  end
end
