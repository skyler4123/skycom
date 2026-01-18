require "application_system_test_case"

class SystemSubscriptionPlansTest < ApplicationSystemTestCase
  setup do
    @system_subscription_plan = system_subscription_plans(:one)
  end

  test "visiting the index" do
    visit system_subscription_plans_url
    assert_selector "h1", text: "System subscription plans"
  end

  test "should create system subscription plan" do
    visit system_subscription_plans_url
    click_on "New system subscription plan"

    fill_in "Business type", with: @system_subscription_plan.business_type
    fill_in "Code", with: @system_subscription_plan.code
    fill_in "Country code", with: @system_subscription_plan.country_code
    fill_in "Description", with: @system_subscription_plan.description
    fill_in "Discarded at", with: @system_subscription_plan.discarded_at
    fill_in "Lifecycle status", with: @system_subscription_plan.lifecycle_status
    fill_in "Name", with: @system_subscription_plan.name
    fill_in "Price", with: @system_subscription_plan.price_id
    fill_in "Workflow status", with: @system_subscription_plan.workflow_status
    click_on "Create System subscription plan"

    assert_text "System subscription plan was successfully created"
    click_on "Back"
  end

  test "should update System subscription plan" do
    visit system_subscription_plan_url(@system_subscription_plan)
    click_on "Edit this system subscription plan", match: :first

    fill_in "Business type", with: @system_subscription_plan.business_type
    fill_in "Code", with: @system_subscription_plan.code
    fill_in "Country code", with: @system_subscription_plan.country_code
    fill_in "Description", with: @system_subscription_plan.description
    fill_in "Discarded at", with: @system_subscription_plan.discarded_at.to_s
    fill_in "Lifecycle status", with: @system_subscription_plan.lifecycle_status
    fill_in "Name", with: @system_subscription_plan.name
    fill_in "Price", with: @system_subscription_plan.price_id
    fill_in "Workflow status", with: @system_subscription_plan.workflow_status
    click_on "Update System subscription plan"

    assert_text "System subscription plan was successfully updated"
    click_on "Back"
  end

  test "should destroy System subscription plan" do
    visit system_subscription_plan_url(@system_subscription_plan)
    accept_confirm { click_on "Destroy this system subscription plan", match: :first }

    assert_text "System subscription plan was successfully destroyed"
  end
end
