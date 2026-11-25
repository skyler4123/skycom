# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TaxCodes Management", type: :feature, js: true do
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

  scenario "shows the empty state and creates a tax code" do
    visit company_tax_codes_path(company)

    expect(page).to have_content("Tax Codes", wait: 10)
    expect(page).to have_content("No tax codes yet", wait: 10)

    click_button "Add tax code"

    find('input[name="tax_code[name]"]', wait: 10).set("VAT 10%")
    find('input[name="tax_code[code]"]').set("VAT10")
    select "VAT", from: "tax_code[kind]"
    find('input[name="tax_code[rate_percent]"]').set("10")
    select "Prices include this tax", from: "tax_code[is_inclusive]"
    click_button "Save tax code"

    expect(page).to have_content("VAT 10%", wait: 10)
    expect(page).to have_content("10%")
    expect(page).to have_content("Included in price")

    code = company.tax_codes.last
    expect(code.rate_bp).to eq(1_000)
    expect(code.is_inclusive).to be(true)
  end

  scenario "edits a tax code rate" do
    create(:tax_code, company: company, name: "VAT 10%", code: "VAT10", rate_bp: 1_000)

    visit company_tax_codes_path(company)
    expect(page).to have_content("VAT 10%", wait: 10)

    find("button[data-action*='openEditModal']", match: :first).click
    find('input[name="tax_code[rate_percent]"]', wait: 10).set("8")
    click_button "Save tax code"

    expect(page).to have_content("8%", wait: 10)
    expect(company.tax_codes.find_by(code: "VAT10").rate_bp).to eq(800)
  end

  scenario "discards a tax code after confirmation" do
    code = create(:tax_code, company: company, name: "VAT 10%", code: "VAT10")

    visit company_tax_codes_path(company)
    expect(page).to have_content("VAT 10%", wait: 10)

    find("button[data-action*='discardTaxCode']", match: :first).click
    click_button "Discard"

    expect(page).to have_content("No tax codes yet", wait: 10)
    expect(code.reload).to be_discarded
  end
end
