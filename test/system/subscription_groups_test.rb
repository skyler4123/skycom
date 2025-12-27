require "application_system_test_case"

class SubscriptionGroupsTest < ApplicationSystemTestCase
  setup do
    @subscription_group = subscription_groups(:one)
  end

  test "visiting the index" do
    visit subscription_groups_url
    assert_selector "h1", text: "Subscription groups"
  end

  test "should create subscription group" do
    visit subscription_groups_url
    click_on "New subscription group"

    check "Auto renew" if @subscription_group.auto_renew
    fill_in "Business type", with: @subscription_group.business_type
    fill_in "Code", with: @subscription_group.code
    fill_in "Country code", with: @subscription_group.country_code
    fill_in "Description", with: @subscription_group.description
    fill_in "Discarded at", with: @subscription_group.discarded_at
    fill_in "Lifecycle status", with: @subscription_group.lifecycle_status
    fill_in "Name", with: @subscription_group.name
    fill_in "Period", with: @subscription_group.period_id
    fill_in "Price", with: @subscription_group.price_id
    fill_in "Workflow status", with: @subscription_group.workflow_status
    click_on "Create Subscription group"

    assert_text "Subscription group was successfully created"
    click_on "Back"
  end

  test "should update Subscription group" do
    visit subscription_group_url(@subscription_group)
    click_on "Edit this subscription group", match: :first

    check "Auto renew" if @subscription_group.auto_renew
    fill_in "Business type", with: @subscription_group.business_type
    fill_in "Code", with: @subscription_group.code
    fill_in "Country code", with: @subscription_group.country_code
    fill_in "Description", with: @subscription_group.description
    fill_in "Discarded at", with: @subscription_group.discarded_at.to_s
    fill_in "Lifecycle status", with: @subscription_group.lifecycle_status
    fill_in "Name", with: @subscription_group.name
    fill_in "Period", with: @subscription_group.period_id
    fill_in "Price", with: @subscription_group.price_id
    fill_in "Workflow status", with: @subscription_group.workflow_status
    click_on "Update Subscription group"

    assert_text "Subscription group was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscription group" do
    visit subscription_group_url(@subscription_group)
    accept_confirm { click_on "Destroy this subscription group", match: :first }

    assert_text "Subscription group was successfully destroyed"
  end
end
