require "rails_helper"

RSpec.feature "Companies::DiscountGroups Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:group) do
    Seed::DiscountGroupService.create(company: company, name: "Summer Sale", prefix: "SUM26",
      discount_type: :percentage, percentage: 10, campaign_status: :paused,
      total_budget_cents: 10_000)
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

  scenario "edit form is prefilled" do
    visit edit_company_discount_group_path(company, group)

    expect(page).to have_selector('input[name="discount_group[name]"]', wait: 10)
    expect(find('input[name="discount_group[name]"]').value).to eq("Summer Sale")
    expect(find('input[name="discount_group[prefix]"]').value).to eq("SUM26")
    expect(find('input[name="discount_group[percentage]"]').value).to eq("10.0")
    expect(find('input[name="discount_group[total_budget_cents]"]').value).to eq("10000")
    expect(find('select[name="discount_group[campaign_status]"]').value).to eq("paused")
  end

  scenario "save redirects to show page with updated values" do
    visit edit_company_discount_group_path(company, group)
    expect(page).to have_selector('input[name="discount_group[name]"]', wait: 10)

    fill_in "discount_group[name]", with: "Summer Sale 2026"
    fill_in "discount_group[percentage]", with: "15"
    select "active", from: "discount_group[campaign_status]"
    click_button "Save Changes"

    # FLAKY_TESTS §8 — assert navigation FIRST, then content
    expect(page).to have_current_path(company_discount_group_path(company, group), wait: 10)
    expect(page).to have_content("Summer Sale 2026", wait: 10)
    expect(group.reload.percentage.to_f).to eq(15.0)
    expect(group.reload).to be_campaign_status_active
  end
end
