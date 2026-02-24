require "test_helper"

class SystemSubscriptionPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_subscription_plan = system_subscription_plans(:one)
  end

  test "should get index" do
    get system_subscription_plans_url
    assert_response :success
  end

  test "should get new" do
    get new_system_subscription_plan_url
    assert_response :success
  end

  test "should create system_subscription_plan" do
    assert_difference("SystemSubscriptionPlan.count") do
      post system_subscription_plans_url, params: { system_subscription_plan: { business_type: @system_subscription_plan.business_type, code: @system_subscription_plan.code, country_code: @system_subscription_plan.country_code, description: @system_subscription_plan.description, discarded_at: @system_subscription_plan.discarded_at, lifecycle_status: @system_subscription_plan.lifecycle_status, name: @system_subscription_plan.name, price_id: @system_subscription_plan.price_id, workflow_status: @system_subscription_plan.workflow_status } }
    end

    assert_redirected_to system_subscription_plan_url(SystemSubscriptionPlan.last)
  end

  test "should show system_subscription_plan" do
    get system_subscription_plan_url(@system_subscription_plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_subscription_plan_url(@system_subscription_plan)
    assert_response :success
  end

  test "should update system_subscription_plan" do
    patch system_subscription_plan_url(@system_subscription_plan), params: { system_subscription_plan: { business_type: @system_subscription_plan.business_type, code: @system_subscription_plan.code, country_code: @system_subscription_plan.country_code, description: @system_subscription_plan.description, discarded_at: @system_subscription_plan.discarded_at, lifecycle_status: @system_subscription_plan.lifecycle_status, name: @system_subscription_plan.name, price_id: @system_subscription_plan.price_id, workflow_status: @system_subscription_plan.workflow_status } }
    assert_redirected_to system_subscription_plan_url(@system_subscription_plan)
  end

  test "should destroy system_subscription_plan" do
    assert_difference("SystemSubscriptionPlan.count", -1) do
      delete system_subscription_plan_url(@system_subscription_plan)
    end

    assert_redirected_to system_subscription_plans_url
  end
end
