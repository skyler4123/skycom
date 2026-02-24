require "application_system_test_case"

class SystemSubscriptionGroupsTest < ApplicationSystemTestCase
  setup do
    @system_subscription_group = system_subscription_groups(:one)
  end

  test "visiting the index" do
    visit system_subscription_groups_url
    assert_selector "h1", text: "System subscription groups"
  end

  test "should create system subscription group" do
    visit system_subscription_groups_url
    click_on "New system subscription group"

    check "Auto renew" if @system_subscription_group.auto_renew
    fill_in "Business type", with: @system_subscription_group.business_type
    fill_in "Code", with: @system_subscription_group.code
    fill_in "Company group", with: @system_subscription_group.company_group_id
    fill_in "Company", with: @system_subscription_group.company_id
    fill_in "Country code", with: @system_subscription_group.country_code
    fill_in "Description", with: @system_subscription_group.description
    fill_in "Discarded at", with: @system_subscription_group.discarded_at
    fill_in "Lifecycle status", with: @system_subscription_group.lifecycle_status
    fill_in "Name", with: @system_subscription_group.name
    fill_in "Period", with: @system_subscription_group.period_id
    fill_in "System subscription plan", with: @system_subscription_group.system_subscription_plan_id
    fill_in "Workflow status", with: @system_subscription_group.workflow_status
    click_on "Create System subscription group"

    assert_text "System subscription group was successfully created"
    click_on "Back"
  end

  test "should update System subscription group" do
    visit system_subscription_group_url(@system_subscription_group)
    click_on "Edit this system subscription group", match: :first

    check "Auto renew" if @system_subscription_group.auto_renew
    fill_in "Business type", with: @system_subscription_group.business_type
    fill_in "Code", with: @system_subscription_group.code
    fill_in "Company group", with: @system_subscription_group.company_group_id
    fill_in "Company", with: @system_subscription_group.company_id
    fill_in "Country code", with: @system_subscription_group.country_code
    fill_in "Description", with: @system_subscription_group.description
    fill_in "Discarded at", with: @system_subscription_group.discarded_at.to_s
    fill_in "Lifecycle status", with: @system_subscription_group.lifecycle_status
    fill_in "Name", with: @system_subscription_group.name
    fill_in "Period", with: @system_subscription_group.period_id
    fill_in "System subscription plan", with: @system_subscription_group.system_subscription_plan_id
    fill_in "Workflow status", with: @system_subscription_group.workflow_status
    click_on "Update System subscription group"

    assert_text "System subscription group was successfully updated"
    click_on "Back"
  end

  test "should destroy System subscription group" do
    visit system_subscription_group_url(@system_subscription_group)
    accept_confirm { click_on "Destroy this system subscription group", match: :first }

    assert_text "System subscription group was successfully destroyed"
  end
end
