require "rails_helper"

RSpec.feature "Companies::Categories New", type: :feature, js: true do
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

  scenario "preselects the resource from the query param" do
    visit new_company_category_path(company, resource_name: "stock_imports")

    expect(page).to have_select("category[resource_name]", wait: 10)
    expect(find("select[name='category[resource_name]']").value).to eq("stock_imports")
  end

  scenario "lists category-backed resources used by record forms" do
    visit new_company_category_path(company)

    expect(page).to have_select("category[resource_name]", wait: 10)

    option_values = find("select[name='category[resource_name]']").all("option").map(&:value)
    expect(option_values).to include(*%w[orders invoices warehouses stock_imports customer_profiles purchase_items])
  end

  scenario "creates a category with the preselected resource" do
    visit new_company_category_path(company, resource_name: "stock_imports")

    fill_in "category[name]", with: "Monthly Import"
    click_button "Save Category"

    expect(page).to have_current_path(%r{/categories/[0-9a-f-]+$}, wait: 10)

    category = Category.find_by(name: "Monthly Import")
    expect(category).to be_present
    expect(category.resource_name).to eq("stock_imports")
  end

  scenario "keeps the selected resource after a validation failure" do
    create(:category, company: company, name: "Duplicate", resource_name: "stock_imports")

    visit new_company_category_path(company, resource_name: "stock_imports")
    fill_in "category[name]", with: "Duplicate"
    click_button "Save Category"

    expect(page).to have_current_path(new_company_category_path(company), ignore_query: true, wait: 10)
    expect(find("select[name='category[resource_name]']").value).to eq("stock_imports")
    expect(Category.where(company: company, name: "Duplicate", resource_name: "stock_imports").count).to eq(1)
  end
end
