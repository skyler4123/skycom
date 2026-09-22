require "rails_helper"

RSpec.feature "Companies::DiscountGroups New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders phase 1 campaign form with base fields" do
    visit new_company_discount_group_path(company)

    expect(page).to have_selector('input[name="discount_group_name"]', wait: 10)
    expect(page).to have_selector('select[name="discount_group_discount_type"]', wait: 10)
    expect(page).to have_selector('select[name="discount_group_currency"]', wait: 10)
    expect(page).to have_selector('input[name="discount_group_start_at"]', wait: 10)
    expect(page).to have_selector('input[name="discount_group_end_at"]', wait: 10)
  end

  scenario "percentage type swaps the conditional fields" do
    visit new_company_discount_group_path(company)
    expect(page).to have_selector('input[name="discount_group_amount"]', wait: 10)

    select "Percentage (%)", from: "discount_group_discount_type"

    expect(page).to have_selector('input[name="discount_group_percentage"]', wait: 10)
    expect(page).to have_selector('input[name="discount_group_max_cap"]', wait: 10)
    expect(page).not_to have_selector('input[name="discount_group_amount"]')
  end

  scenario "create advances to phase 2 then generates codes" do
    visit new_company_discount_group_path(company)
    expect(page).to have_selector('input[name="discount_group_name"]', wait: 10)

    fill_in "discount_group_name", with: "New Year Event"
    fill_in "discount_group_prefix", with: "NY26"
    fill_in "discount_group_amount", with: "5"
    fill_in "discount_group_total_budget", with: "100"

    click_button "Save Campaign"

    expect(page).to have_selector('#generate-quantity', wait: 10)
    group = DiscountGroup.find_by(name: "New Year Event")
    expect(group).to be_present
    expect(page).to have_content("New Year Event")

    fill_in "generate-quantity", with: "10"
    click_button "Generate Codes"

    expect(page).to have_current_path(company_discount_group_path(company, group), wait: 10)
    expect(group.discounts.count).to eq(10)
    expect(page).to have_content("10 discount codes generated", wait: 10)
  end

  scenario "skip goes straight to the show page" do
    visit new_company_discount_group_path(company)
    expect(page).to have_selector('input[name="discount_group_name"]', wait: 10)

    fill_in "discount_group_name", with: "Skip Test"
    fill_in "discount_group_amount", with: "3"
    click_button "Save Campaign"

    expect(page).to have_selector('#generate-quantity', wait: 10)
    group = DiscountGroup.find_by(name: "Skip Test")
    expect(group).to be_present

    click_link "Skip"

    expect(page).to have_current_path(company_discount_group_path(company, group), wait: 10)
  end

  scenario "generate mode (?generate_for) appends codes to an existing group" do
    group = Seed::DiscountGroupService.create(company: company, name: "Existing", prefix: "EX26",
      discount_type: :fixed_amount, amount_cents: 200)

    visit "#{new_company_discount_group_path(company)}?generate_for=#{group.id}"
    expect(page).to have_selector('#generate-quantity', wait: 10)
    expect(page).to have_content("Existing")

    fill_in "generate-quantity", with: "5"
    click_button "Generate Codes"

    expect(page).to have_current_path(company_discount_group_path(company, group), wait: 10)
    expect(group.discounts.count).to eq(5)
  end

  scenario "validation error from BE keeps phase 1 and toasts" do
    visit new_company_discount_group_path(company)
    expect(page).to have_selector('input[name="discount_group_name"]', wait: 10)

    click_button "Save Campaign"

    expect(page).to have_selector('input[name="discount_group_name"]', wait: 10)
    expect(DiscountGroup.where(name: "")).to be_empty
  end
end
