# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Products property type validation", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }
  let(:category) do
    create(:category, company: company, name: "Test Category", resource_name: "products")
  end

  before do
    category.default_property_mapping.update!(metadata: { "properties" => [
      { "key" => "property_string_1", "type" => "string", "name" => "Brand" },
      { "key" => "property_integer_1", "type" => "integer", "name" => "Quantity" },
      { "key" => "property_decimal_1", "type" => "decimal", "name" => "Price" },
      { "key" => "property_boolean_1", "type" => "boolean", "name" => "Active" },
      { "key" => "property_datetime_1", "type" => "datetime", "name" => "Released At" }
    ] })

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
      enums: {
        product: {
          business_types: [
            { name: "Physical", value: "physical" },
            { name: "Digital", value: "digital" },
            { name: "Service based", value: "service_based" }
          ],
          lifecycle_statuses: [],
          workflow_statuses: []
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  def fill_product_baseline
    fill_in "product[name]", with: "Test Product"
    select "Test Category", from: "product[category_id]"
    expect(page).to have_selector("input[name*='[property_string_1]']", wait: 5)
  end

  scenario "blank property slots are allowed when at least one value is present" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_in "product[property_string_1]", with: "Acme"

    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "string values over 255 characters are rejected" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_in "product[property_string_1]", with: "A" * 256

    click_button "Save Product"

    expect(page).to have_content("Property string 1 is too long (maximum is 255 characters)", wait: 10)

    fill_product_baseline
    fill_in "product[property_string_1]", with: "Acme"
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "integer values outside the 32-bit range are rejected" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_in "product[property_integer_1]", with: "2147483648"

    click_button "Save Product"

    expect(page).to have_content("Property integer 1 must be between -2147483648 and 2147483647", wait: 10)

    fill_product_baseline
    fill_in "product[property_integer_1]", with: "10"
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "decimal values with more than four decimal places are rejected" do
    visit new_company_product_path(company)
    fill_product_baseline
    page.execute_script("document.querySelector('form').noValidate = true")
    fill_in "product[property_decimal_1]", with: "12.34567"

    click_button "Save Product"

    expect(page).to have_content("Property decimal 1 must have at most 4 decimal places", wait: 10)

    fill_product_baseline
    page.execute_script("document.querySelector('form').noValidate = true")
    fill_in "product[property_decimal_1]", with: "12.3456"
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end
end
