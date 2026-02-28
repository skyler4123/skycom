require "test_helper"

class SubscriptionPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription_plan = subscription_plans(:one)
  end

  test "should get index" do
    get subscription_plans_url
    assert_response :success
  end

  test "should get new" do
    get new_subscription_plan_url
    assert_response :success
  end

  test "should create subscription_plan" do
    assert_difference("SubscriptionPlan.count") do
      post subscription_plans_url, params: { subscription_plan: { auto_renew: @subscription_plan.auto_renew, business_type: @subscription_plan.business_type, code: @subscription_plan.code, company_id: @subscription_plan.company_id, branch_id: @subscription_plan.branch_id, country_code: @subscription_plan.country_code, description: @subscription_plan.description, discarded_at: @subscription_plan.discarded_at, lifecycle_status: @subscription_plan.lifecycle_status, name: @subscription_plan.name, period_id: @subscription_plan.period_id, price_id: @subscription_plan.price_id, workflow_status: @subscription_plan.workflow_status } }
    end

    assert_redirected_to subscription_plan_url(SubscriptionPlan.last)
  end

  test "should show subscription_plan" do
    get subscription_plan_url(@subscription_plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_subscription_plan_url(@subscription_plan)
    assert_response :success
  end

  test "should update subscription_plan" do
    patch subscription_plan_url(@subscription_plan), params: { subscription_plan: { auto_renew: @subscription_plan.auto_renew, business_type: @subscription_plan.business_type, code: @subscription_plan.code, company_id: @subscription_plan.company_id, branch_id: @subscription_plan.branch_id, country_code: @subscription_plan.country_code, description: @subscription_plan.description, discarded_at: @subscription_plan.discarded_at, lifecycle_status: @subscription_plan.lifecycle_status, name: @subscription_plan.name, period_id: @subscription_plan.period_id, price_id: @subscription_plan.price_id, workflow_status: @subscription_plan.workflow_status } }
    assert_redirected_to subscription_plan_url(@subscription_plan)
  end

  test "should destroy subscription_plan" do
    assert_difference("SubscriptionPlan.count", -1) do
      delete subscription_plan_url(@subscription_plan)
    end

    assert_redirected_to subscription_plans_url
  end
end
