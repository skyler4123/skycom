require "rails_helper"

RSpec.feature "Companies::DiscountGroups Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:summer_group) do
    Seed::DiscountGroupService.create(company: company, name: "Summer Sale", prefix: "SUM26",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end

  let!(:winter_group) do
    Seed::DiscountGroupService.create(company: company, name: "Winter Sale", prefix: "WIN26",
      discount_type: :fixed_amount, amount_cents: 500, campaign_status: :draft)
  end

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

  scenario "index displays campaign groups table" do
    visit company_discount_groups_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Summer Sale", wait: 10)
    expect(page).to have_content("Winter Sale")
    expect(page).to have_content("SUM26")
    expect(page).to have_content("WIN26")
  end

  scenario "new campaign button links to the rich new page" do
    visit company_discount_groups_path(company)
    expect(page).to have_selector("table", wait: 10)

    link = find("a[href*='/discount_groups/new']")
    expect(link).to be_present
  end

  scenario "group name links to show page" do
    visit company_discount_groups_path(company)
    expect(page).to have_selector("table", wait: 10)

    link = find("a[href*='/discount_groups/#{summer_group.id}']", match: :first)
    expect(link).to be_present
  end
end
