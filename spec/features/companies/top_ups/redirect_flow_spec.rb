# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::TopUps::RedirectFlow", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:mock_qr_method) { create(:billing_payment_method, :mock_qr) }
  let(:mock_redirect_method) { create(:billing_payment_method, :mock_redirect) }

  before do
    company.update_columns(country: :us, currency: :usd)
    mock_qr_method
    mock_redirect_method

    allow_any_instance_of(Payments::MockRedirectGateway).to receive(:call).and_return(
      success: true,
      gateway_reference: "MOCK_SESS_#{Time.current.to_i}",
      gateway_payload: {
        redirect_url: "http://example.com/checkout?session_id=test_session"
      }
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

  scenario "creates a pending transaction after redirect submission" do
    expect {
      visit new_company_top_up_path(company)
      fill_in "top-up-amount", with: "150"
      find(".payment-method-card", text: "Mock Redirect").click
      click_button "Confirm Top Up"
      sleep 0.5
    }.to change(BillingTransaction, :count).by(1)

    txn = BillingTransaction.last
    expect(txn.status).to eq("pending")
    expect(txn.amount_cents).to eq(15000)
    expect(txn.transaction_type).to eq("top_up")
  end

  context "with VN company" do
    let(:vn_company) { create(:company) }
    let(:vn_owner) { vn_company.user }

    before do
      vn_company.update_columns(country: :vn, currency: :vnd)
      mock_qr_method
      mock_redirect_method

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

    scenario "creates a pending transaction for VN company" do
      expect {
        visit new_company_top_up_path(vn_company)
        fill_in "top-up-amount", with: "200000"
        find(".payment-method-card", text: "Mock Redirect").click
        click_button "Confirm Top Up"
        sleep 0.5
      }.to change(BillingTransaction, :count).by(1)

      txn = BillingTransaction.last
      expect(txn.amount_cents).to eq(200000)
    end
  end
end
