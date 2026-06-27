require "rails_helper"

RSpec.feature "Companies::Dashboards", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:category) do
    Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "products")
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

  scenario "displays company name and business type" do
    visit company_dashboards_path(company)

    expect(page).to have_content(company.name, wait: 10)
    expect(page).to have_content(company.business_type.tr("_", " ").titleize, wait: 10)
  end

  scenario "displays company contact info" do
    visit company_dashboards_path(company)

    expect(page).to have_content(company.email, wait: 10)
    expect(page).to have_content(company.phone_number, wait: 10)
  end

  scenario "shows total count badges for resources with records" do
    Product.create!(company: company, name: "Test Product", category: category, business_type: "physical")
    Product.create!(company: company, name: "Test Product 2", category: category, business_type: "physical")
    Product.create!(company: company, name: "Test Product 3", category: category, business_type: "physical")

    visit company_dashboards_path(company)

    chart_card = find('[data-chart="products"]', wait: 10)
    expect(chart_card).to be_present

    expect(page).to have_content("Products", wait: 10)
    expect(page).to have_content("3", wait: 10)
  end

  scenario "shows all five chart cards" do
    visit company_dashboards_path(company)

    %w[products stocks services orders employees].each do |resource|
      expect(page).to have_selector('[data-chart="' + resource + '"]', wait: 10)
    end
  end

  scenario "shows no data for resources without records" do
    visit company_dashboards_path(company)

    expect(page).to have_text("No data", count: 4, wait: 10)
  end

  scenario "displays total across multiple categories" do
    category2 = Seed::CategoryService.create(company: company, name: "Category B", resource_name: "products")

    Product.create!(company: company, name: "P1", category: category, business_type: "physical")
    Product.create!(company: company, name: "P2", category: category, business_type: "physical")
    Product.create!(company: company, name: "P3", category: category2, business_type: "physical")
    Product.create!(company: company, name: "P4", category: category2, business_type: "physical")

    visit company_dashboards_path(company)

    expect(page).to have_content("Products", wait: 10)
    expect(page).to have_content("4", wait: 10)
  end

  scenario "renders charts when data exists" do
    Product.create!(company: company, name: "Chart Product", category: category, business_type: "physical")
    Product.create!(company: company, name: "Chart Product 2", category: category, business_type: "physical")

    visit company_dashboards_path(company)

    chart_container = find('[data-chart="products"]', wait: 10)
    expect(chart_container).to have_selector("svg", wait: 10)
  end
end
