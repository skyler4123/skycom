# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TopUps", type: :feature, js: true do
  let(:company) { create(:company, country: :us, currency: :usd) }
  let(:owner) { company.user }

  before do
    create(:company_payment_method, :mock_qr)
    create(:company_payment_method, :mock_redirect)

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

  scenario "shows country-based top-up options" do
    visit new_company_top_up_path(company)

    expect(page).to have_content(/top up options/i, wait: 10)
    expect(page).to have_content("$5.00", wait: 10)
    expect(page).to have_content("500,000", wait: 10)
    expect(page).to have_content("$10.00", wait: 10)
    expect(page).to have_content("1,000,000", wait: 10)
  end

  scenario "shows the company's b2b payment options" do
    visit new_company_top_up_path(company)

    expect(page).to have_content("Mock QR", wait: 10)
    expect(page).to have_content("Mock Redirect", wait: 10)
  end

  scenario "starts a Mock QR top-up and shows the QR wait screen" do
    allow(Payments::MockQrGateway).to receive(:new).and_return(
      double(call: { success: true, gateway_reference: "MOCK_QR_FEATURE", gateway_payload: { "qr_string" => "000201MOCKQR" } })
    )

    visit new_company_top_up_path(company)

    find('[data-companies--top-ups--new-money-cents-param="500"]', wait: 10).click
    find(".payment-method-card", text: "Mock QR").click
    click_button "Confirm Top Up"

    expect(page).to have_content("Scan to Pay", wait: 10)
    expect(page).to have_selector("#qr-container img", wait: 10)

    txn = CompanyTransaction.last
    expect(txn.status).to eq("pending")
    expect(txn.gateway_reference).to start_with("TOPUP_")
  end
end
