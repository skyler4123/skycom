require "test_helper"

class SystemSubscriptionGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_subscription_group = system_subscription_groups(:one)
  end

  test "should get index" do
    get system_subscription_groups_url
    assert_response :success
  end

  test "should get new" do
    get new_system_subscription_group_url
    assert_response :success
  end

  test "should create system_subscription_group" do
    assert_difference("SystemSubscriptionGroup.count") do
      post system_subscription_groups_url, params: { system_subscription_group: { auto_renew: @system_subscription_group.auto_renew, business_type: @system_subscription_group.business_type, code: @system_subscription_group.code, company_id: @system_subscription_group.company_id, branch_id: @system_subscription_group.branch_id, country_code: @system_subscription_group.country_code, description: @system_subscription_group.description, discarded_at: @system_subscription_group.discarded_at, lifecycle_status: @system_subscription_group.lifecycle_status, name: @system_subscription_group.name, period_id: @system_subscription_group.period_id, system_subscription_plan_id: @system_subscription_group.system_subscription_plan_id, workflow_status: @system_subscription_group.workflow_status } }
    end

    assert_redirected_to system_subscription_group_url(SystemSubscriptionGroup.last)
  end

  test "should show system_subscription_group" do
    get system_subscription_group_url(@system_subscription_group)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_subscription_group_url(@system_subscription_group)
    assert_response :success
  end

  test "should update system_subscription_group" do
    patch system_subscription_group_url(@system_subscription_group), params: { system_subscription_group: { auto_renew: @system_subscription_group.auto_renew, business_type: @system_subscription_group.business_type, code: @system_subscription_group.code, company_id: @system_subscription_group.company_id, branch_id: @system_subscription_group.branch_id, country_code: @system_subscription_group.country_code, description: @system_subscription_group.description, discarded_at: @system_subscription_group.discarded_at, lifecycle_status: @system_subscription_group.lifecycle_status, name: @system_subscription_group.name, period_id: @system_subscription_group.period_id, system_subscription_plan_id: @system_subscription_group.system_subscription_plan_id, workflow_status: @system_subscription_group.workflow_status } }
    assert_redirected_to system_subscription_group_url(@system_subscription_group)
  end

  test "should destroy system_subscription_group" do
    assert_difference("SystemSubscriptionGroup.count", -1) do
      delete system_subscription_group_url(@system_subscription_group)
    end

    assert_redirected_to system_subscription_groups_url
  end
end
