require "rails_helper"

RSpec.feature "Companies::Taxes Management", type: :feature, js: true do
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

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "tax page loads and displays summary" do
    visit company_tax_path(company)

    expect(page).to have_content("Export CSV", wait: 10)
  end

  scenario "shows only invoices inside the requested period" do
    invoice_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "invoices")
    customer = create(:customer, company: company)

    in_range = create(:invoice, company: company, category: invoice_category,
      order: create(:order, company: company, customer: customer), discarded_at: nil)
    in_range.update_columns(created_at: Time.zone.local(2026, 1, 15, 12), updated_at: Time.zone.local(2026, 1, 15, 12))

    out_of_range = create(:invoice, company: company, category: invoice_category,
      order: create(:order, company: company, customer: customer), discarded_at: nil)
    out_of_range.update_columns(created_at: Time.zone.local(2025, 12, 15, 12), updated_at: Time.zone.local(2025, 12, 15, 12))

    visit company_tax_path(company, from: "2026-01-01", to: "2026-01-31")

    expect(page).to have_content(in_range.code, wait: 10)
    expect(page).not_to have_content(out_of_range.code)
  end
end
