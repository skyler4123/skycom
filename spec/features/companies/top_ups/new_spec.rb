# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TopUps::New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:mock_qr_method) { create(:billing_payment_method, :mock_qr) }
  let(:mock_redirect_method) { create(:billing_payment_method, :mock_redirect) }

  before do
    company.update_columns(country: :us, currency: :usd)
    mock_qr_method
    mock_redirect_method

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

  scenario "page loads with Top Up title" do
    visit new_company_top_up_path(company)
    expect(page).to have_css("*", text: "Top Up Wallet", visible: false, wait: 10)
  end

  scenario "shows amount input field" do
    visit new_company_top_up_path(company)
    expect(page).to have_css("*", text: "Amount", visible: false, wait: 10)
    expect(page).to have_selector('input[type="number"]', wait: 10)
  end

  scenario "shows payment method cards" do
    visit new_company_top_up_path(company)
    expect(page).to have_css("*", text: "Payment Method", visible: false, wait: 10)
    expect(page).to have_css("*", text: "Mock QR", visible: false, wait: 10)
    expect(page).to have_css("*", text: "Mock Redirect", visible: false, wait: 10)
  end

  scenario "shows Confirm Top Up button" do
    visit new_company_top_up_path(company)
    expect(page).to have_css("*", text: "Confirm Top Up", visible: false, wait: 10)
  end

  scenario "shows Back to Billing link" do
    visit new_company_top_up_path(company)
    expect(page).to have_link("Back to Billing", href: "/companies/#{company.id}/billing", visible: :all, wait: 10)
  end

  scenario "selects a payment method on click" do
    visit new_company_top_up_path(company)
    expect(page).to have_css("*", text: "Mock QR", visible: false, wait: 10)

    find(".payment-method-card", text: "Mock QR").click
    expect(page).to have_css(".payment-method-card.border-blue-500", visible: false, wait: 10)
  end

  context "with a VN company" do
    let(:vn_company) { create(:company) }
    let(:vn_owner) { vn_company.user }

    before do
      vn_company.update_columns(country: :vn, currency: :vnd)
      mock_qr_method
      mock_redirect_method

      sign_in(vn_owner)

      page.execute_script("localStorage.clear()")
      company_data = JSON.parse(vn_company.to_json).merge(
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

    scenario "page loads with payment methods for VN company" do
      visit new_company_top_up_path(vn_company)
      expect(page).to have_css("*", text: "Top Up Wallet", visible: false, wait: 10)
      expect(page).to have_css("*", text: "Mock QR", visible: false, wait: 10)
      expect(page).to have_css("*", text: "Mock Redirect", visible: false, wait: 10)
    end

    scenario "selects a payment method for VN company" do
      visit new_company_top_up_path(vn_company)
      find(".payment-method-card", text: "Mock Redirect").click
      expect(page).to have_css(".payment-method-card.border-blue-500", visible: false, wait: 10)
    end
  end
end
