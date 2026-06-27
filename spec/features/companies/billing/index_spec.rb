require "rails_helper"

RSpec.feature "Companies::Billing", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
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

  scenario "page loads with KPI cards" do
    visit company_billing_path(company)

    body_html = page.evaluate_script('document.body ? document.body.innerHTML.substring(0, 1000) : "no body"')
    puts "=== Body HTML: #{body_html}"

    page_title = page.evaluate_script('document.title')
    puts "=== Title: #{page_title}"

    expect(page).to have_text("Billing Status", wait: 10)
    expect(page).to have_text("Wallet Balance", wait: 10)
    expect(page).to have_text("This Month Estimate", wait: 10)
  end

  scenario "shows usage metrics section" do
    visit company_billing_path(company)

    expect(page).to have_text("Usage Metrics", wait: 10)
  end

  scenario "shows enabled add-on features section" do
    visit company_billing_path(company)

    expect(page).to have_text("Enabled Add-on Features", wait: 10)
  end

  scenario "shows outstanding invoices section" do
    visit company_billing_path(company)

    expect(page).to have_text("Outstanding Invoices", wait: 10)
  end

  scenario "sidebar has billing link" do
    visit company_billing_path(company)

    expect(page).to have_link("Billing", href: "/companies/#{company.id}/billing", wait: 10)
  end

  scenario "shows charts containers" do
    visit company_billing_path(company)

    expect(page).to have_text("Usage vs Allowance", wait: 10)
    expect(page).to have_text("Cost Breakdown", wait: 10)
  end
end
