# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TopUps::QrFlow", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:mock_qr_method) { create(:billing_payment_method, :mock_qr) }
  let(:mock_redirect_method) { create(:billing_payment_method, :mock_redirect) }

  before do
    company.update_columns(country: :us, currency: :usd)
    mock_qr_method
    mock_redirect_method

    allow_any_instance_of(Payments::MockQrGateway).to receive(:call).and_return(
      success: true,
      gateway_reference: "MOCK_QR_#{Time.current.to_i}",
      gateway_payload: {
        qr_string: "00020101021238580010A0000|AMT:5000|INV:test|TOKEN:test|TXN:test"
      }
    )

    page.execute_script(
      "window.WEBSOCKET = window.WEBSOCKET || " \
      "{ subscribe: function() {}, companyChannel: function() { return null } }"
    )

    sign_in(owner)

    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [], "table_configs" => [], "categories" => [],
      "branches" => [], "departments" => [], "roles" => []
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

  scenario "shows QR wait screen after submitting QR payment" do
    visit new_company_top_up_path(company)
    expect(page).to have_css("*", text: "Top Up Wallet", visible: false, wait: 10)

    fill_in "top-up-amount", with: "50"
    find(".payment-method-card", text: "Mock QR").click
    click_button "Confirm Top Up"

    expect(page).to have_css("*", text: "Scan to Pay", visible: false, wait: 10)
    expect(page).to have_css("*", text: "Waiting for payment confirmation", visible: false, wait: 10)
  end

  scenario "shows formatted amount on QR screen (USD)" do
    visit new_company_top_up_path(company)
    fill_in "top-up-amount", with: "50"
    find(".payment-method-card", text: "Mock QR").click
    click_button "Confirm Top Up"

    expect(page).to have_css("*", text: "$50.00", visible: false, wait: 10)
  end

  scenario "QR container is rendered on the wait screen" do
    visit new_company_top_up_path(company)
    fill_in "top-up-amount", with: "25"
    find(".payment-method-card", text: "Mock QR").click
    click_button "Confirm Top Up"

    expect(page).to have_selector("#qr-container", visible: false, wait: 10)
  end

  scenario "Cancel button returns to form" do
    visit new_company_top_up_path(company)
    fill_in "top-up-amount", with: "50"
    find(".payment-method-card", text: "Mock QR").click
    click_button "Confirm Top Up"

    expect(page).to have_css("*", text: "Scan to Pay", visible: false, wait: 10)

    click_button "Cancel"

    expect(page).to have_css("*", text: "Top Up Wallet", visible: false, wait: 10)
  end

  context "with VN company" do
    let(:vn_company) { create(:company) }
    let(:vn_owner) { vn_company.user }

    before do
      vn_company.update_columns(country: :vn, currency: :vnd)
      mock_qr_method
      mock_redirect_method

      page.execute_script(
        "window.WEBSOCKET = window.WEBSOCKET || " \
        "{ subscribe: function() {}, companyChannel: function() { return null } }"
      )

      sign_in(vn_owner)

      page.execute_script("localStorage.clear()")
      company_data = JSON.parse(vn_company.to_json).merge(
        "currency" => "vnd",
        "property_mappings" => [], "table_configs" => [], "categories" => [],
        "branches" => [], "departments" => [], "roles" => []
      )
      payload = {
        user: JSON.parse(vn_owner.to_json),
        companies: [ company_data ],
        enums: {},
        employees: []
      }
      page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
      page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
      page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
    end

    scenario "shows VND formatted amount on QR screen" do
      visit new_company_top_up_path(vn_company)
      fill_in "top-up-amount", with: "50000"
      find(".payment-method-card", text: "Mock QR").click
      click_button "Confirm Top Up"

      # vi-VN locale uses . as grouping separator
      expect(page).to have_css("*", text: "50.000₫", visible: false, wait: 10)
    end
  end
end
