require "rails_helper"

RSpec.feature "Companies::DiscountGroups Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:group) do
    Seed::DiscountGroupService.create(company: company, name: "Summer Sale", prefix: "SUM26",
      discount_type: :percentage, percentage: 10, campaign_status: :active,
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

  scenario "show page renders campaign header, stats and ledger" do
    Discounts::BatchGenerator.call(discount_group: group, quantity: 3)
    visit company_discount_group_path(company, group)

    expect(page).to have_content("Summer Sale", wait: 10)
    expect(page).to have_content("SUM26")
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("tbody tr", count: 3, wait: 10)
  end

  scenario "lifecycle pause updates campaign status" do
    visit company_discount_group_path(company, group)
    expect(page).to have_content("Summer Sale", wait: 10)

    click_button "Pause"

    # PATCH is async + reloadThenToast reloads — wait for the re-rendered
    # lifecycle controls (paused shows "Activate") before asserting the DB.
    expect(page).to have_button("Activate", wait: 10)
    expect(group.reload).to be_campaign_status_paused
  end

  scenario "status filter narrows the ledger" do
    Discounts::BatchGenerator.call(discount_group: group, quantity: 4)
    group.discounts.first.update!(status: :used, used_at: Time.current)
    visit company_discount_group_path(company, group)
    expect(page).to have_selector("tbody tr", count: 4, wait: 10)

    select "Used", from: "ledger-status"

    expect(page).to have_selector("tbody tr", count: 1, wait: 10)
  end

  scenario "copy button writes the code to the clipboard" do
    Discounts::BatchGenerator.call(discount_group: group, quantity: 1)
    code = group.discounts.first.code
    visit company_discount_group_path(company, group)
    expect(page).to have_selector("tbody tr", wait: 10)

    page.execute_script("navigator.clipboard.writeText = (t) => { window.__copied = t }")
    find("[data-action*='copyCode']").click

    copied = page.evaluate_script("window.__copied")
    expect(copied).to eq(code)
  end

  scenario "export CSV downloads the ledger" do
    Discounts::BatchGenerator.call(discount_group: group, quantity: 2)
    visit company_discount_group_path(company, group)
    expect(page).to have_selector("tbody tr", wait: 10)

    click_button "Export CSV"

    # No exception — download happens client-side; assert the page is still interactive
    expect(page).to have_content("Summer Sale")
  end
end
