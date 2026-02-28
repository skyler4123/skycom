require "application_system_test_case"

class SubscriptionPlansTest < ApplicationSystemTestCase
  setup do
    @subscription_plan = subscription_plans(:one)
  end

  test "visiting the index" do
    visit subscription_plans_url
    assert_selector "h1", text: "Subscription plans"
  end

  test "should create subscription plan" do
    visit subscription_plans_url
    click_on "New subscription plan"

    check "Auto renew" if @subscription_plan.auto_renew
    fill_in "Business type", with: @subscription_plan.business_type
    fill_in "Code", with: @subscription_plan.code
    fill_in "Company group", with: @subscription_plan.company_id
    fill_in "Company", with: @subscription_plan.branch_id
    fill_in "Country code", with: @subscription_plan.country_code
    fill_in "Description", with: @subscription_plan.description
    fill_in "Discarded at", with: @subscription_plan.discarded_at
    fill_in "Lifecycle status", with: @subscription_plan.lifecycle_status
    fill_in "Name", with: @subscription_plan.name
    fill_in "Period", with: @subscription_plan.period_id
    fill_in "Price", with: @subscription_plan.price_id
    fill_in "Workflow status", with: @subscription_plan.workflow_status
    click_on "Create Subscription plan"

    assert_text "Subscription plan was successfully created"
    click_on "Back"
  end

  test "should update Subscription plan" do
    visit subscription_plan_url(@subscription_plan)
    click_on "Edit this subscription plan", match: :first

    check "Auto renew" if @subscription_plan.auto_renew
    fill_in "Business type", with: @subscription_plan.business_type
    fill_in "Code", with: @subscription_plan.code
    fill_in "Company group", with: @subscription_plan.company_id
    fill_in "Company", with: @subscription_plan.branch_id
    fill_in "Country code", with: @subscription_plan.country_code
    fill_in "Description", with: @subscription_plan.description
    fill_in "Discarded at", with: @subscription_plan.discarded_at.to_s
    fill_in "Lifecycle status", with: @subscription_plan.lifecycle_status
    fill_in "Name", with: @subscription_plan.name
    fill_in "Period", with: @subscription_plan.period_id
    fill_in "Price", with: @subscription_plan.price_id
    fill_in "Workflow status", with: @subscription_plan.workflow_status
    click_on "Update Subscription plan"

    assert_text "Subscription plan was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscription plan" do
    visit subscription_plan_url(@subscription_plan)
    accept_confirm { click_on "Destroy this subscription plan", match: :first }

    assert_text "Subscription plan was successfully destroyed"
  end
end
