require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  setup do
    @subscription = subscriptions(:one)
  end

  test "visiting the index" do
    visit subscriptions_url
    assert_selector "h1", text: "Subscriptions"
  end

  test "should create subscription" do
    visit subscriptions_url
    click_on "New subscription"

    check "Auto renew" if @subscription.auto_renew
    fill_in "Business type", with: @subscription.business_type
    fill_in "Code", with: @subscription.code
    fill_in "Country code", with: @subscription.country_code
    fill_in "Description", with: @subscription.description
    fill_in "Discarded at", with: @subscription.discarded_at
    fill_in "Lifecycle status", with: @subscription.lifecycle_status
    fill_in "Name", with: @subscription.name
    fill_in "Period", with: @subscription.period_id
    fill_in "Price", with: @subscription.price_id
    fill_in "Subscription group", with: @subscription.subscription_group_id
    fill_in "Workflow status", with: @subscription.workflow_status
    click_on "Create Subscription"

    assert_text "Subscription was successfully created"
    click_on "Back"
  end

  test "should update Subscription" do
    visit subscription_url(@subscription)
    click_on "Edit this subscription", match: :first

    check "Auto renew" if @subscription.auto_renew
    fill_in "Business type", with: @subscription.business_type
    fill_in "Code", with: @subscription.code
    fill_in "Country code", with: @subscription.country_code
    fill_in "Description", with: @subscription.description
    fill_in "Discarded at", with: @subscription.discarded_at.to_s
    fill_in "Lifecycle status", with: @subscription.lifecycle_status
    fill_in "Name", with: @subscription.name
    fill_in "Period", with: @subscription.period_id
    fill_in "Price", with: @subscription.price_id
    fill_in "Subscription group", with: @subscription.subscription_group_id
    fill_in "Workflow status", with: @subscription.workflow_status
    click_on "Update Subscription"

    assert_text "Subscription was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscription" do
    visit subscription_url(@subscription)
    accept_confirm { click_on "Destroy this subscription", match: :first }

    assert_text "Subscription was successfully destroyed"
  end
end
