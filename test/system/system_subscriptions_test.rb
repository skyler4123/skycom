require "application_system_test_case"

class SystemSubscriptionsTest < ApplicationSystemTestCase
  setup do
    @system_subscription = system_subscriptions(:one)
  end

  test "visiting the index" do
    visit system_subscriptions_url
    assert_selector "h1", text: "System subscriptions"
  end

  test "should create system subscription" do
    visit system_subscriptions_url
    click_on "New system subscription"

    check "Auto renew" if @system_subscription.auto_renew
    fill_in "Business type", with: @system_subscription.business_type
    fill_in "Code", with: @system_subscription.code
    fill_in "Company group", with: @system_subscription.company_id
    fill_in "Company", with: @system_subscription.branch_id
    fill_in "Country code", with: @system_subscription.country_code
    fill_in "Description", with: @system_subscription.description
    fill_in "Discarded at", with: @system_subscription.discarded_at
    fill_in "Lifecycle status", with: @system_subscription.lifecycle_status
    fill_in "Name", with: @system_subscription.name
    fill_in "Period", with: @system_subscription.period_id
    fill_in "Price", with: @system_subscription.price_id
    fill_in "Subscription group", with: @system_subscription.subscription_group_id
    fill_in "System subscription plan", with: @system_subscription.system_subscription_plan_id
    fill_in "Workflow status", with: @system_subscription.workflow_status
    click_on "Create System subscription"

    assert_text "System subscription was successfully created"
    click_on "Back"
  end

  test "should update System subscription" do
    visit system_subscription_url(@system_subscription)
    click_on "Edit this system subscription", match: :first

    check "Auto renew" if @system_subscription.auto_renew
    fill_in "Business type", with: @system_subscription.business_type
    fill_in "Code", with: @system_subscription.code
    fill_in "Company group", with: @system_subscription.company_id
    fill_in "Company", with: @system_subscription.branch_id
    fill_in "Country code", with: @system_subscription.country_code
    fill_in "Description", with: @system_subscription.description
    fill_in "Discarded at", with: @system_subscription.discarded_at.to_s
    fill_in "Lifecycle status", with: @system_subscription.lifecycle_status
    fill_in "Name", with: @system_subscription.name
    fill_in "Period", with: @system_subscription.period_id
    fill_in "Price", with: @system_subscription.price_id
    fill_in "Subscription group", with: @system_subscription.subscription_group_id
    fill_in "System subscription plan", with: @system_subscription.system_subscription_plan_id
    fill_in "Workflow status", with: @system_subscription.workflow_status
    click_on "Update System subscription"

    assert_text "System subscription was successfully updated"
    click_on "Back"
  end

  test "should destroy System subscription" do
    visit system_subscription_url(@system_subscription)
    accept_confirm { click_on "Destroy this system subscription", match: :first }

    assert_text "System subscription was successfully destroyed"
  end
end
