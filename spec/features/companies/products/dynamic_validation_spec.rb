# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Products Dynamic Validation", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }
  let(:category) do
    create(:category, company: company, name: "Test Category", resource_name: "products")
  end

  before do
    category.default_property_mapping.update!(property_metadata: [
      { "key" => "property_string_1", "name" => "presence_test", "type" => "string", "label" => "Presence Test",
        "validates" => { "presence" => true } },
      { "key" => "property_integer_1", "name" => "numericality_test", "type" => "integer", "label" => "Num Test",
        "validates" => { "numericality" => { "only_integer" => true, "greater_than_or_equal_to" => 0, "less_than" => 100 } } },
      { "key" => "property_string_2", "name" => "inclusion_test", "type" => "string", "label" => "Incl Test",
        "validates" => { "inclusion" => { "in" => [ "Option A", "Option B" ] } } },
      { "key" => "property_string_3", "name" => "format_test", "type" => "string", "label" => "Fmt Test",
        "validates" => { "format" => { "with" => "^SKU-" } } },
      { "key" => "property_string_4", "name" => "length_test", "type" => "string", "label" => "Len Test",
        "validates" => { "length" => { "minimum" => 2, "maximum" => 50 } } }
    ])

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

  def fill_valid_properties
    fill_in "product[property_string_1]", with: "SomeValue"
    fill_in "product[property_integer_1]", with: "10"
    fill_in "product[property_string_2]", with: "Option A"
    fill_in "product[property_string_3]", with: "SKU-001"
    fill_in "product[property_string_4]", with: "Valid Value"
  end

  scenario "presence validation blocks blank property_string_1" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_valid_properties
    fill_in "product[property_string_1]", with: ""

    click_button "Save Product"

    expect(page).to have_content("Property string 1 can't be blank", wait: 10)

    fill_product_baseline
    fill_valid_properties
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "numericality greater_than_or_equal_to blocks negative value" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_valid_properties
    fill_in "product[property_integer_1]", with: "-1"

    click_button "Save Product"

    expect(page).to have_content("Property integer 1 must be greater than or equal to 0", wait: 10)

    fill_product_baseline
    fill_valid_properties
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "numericality less_than blocks value at or above threshold" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_valid_properties
    fill_in "product[property_integer_1]", with: "100"

    click_button "Save Product"

    expect(page).to have_content("Property integer 1 must be less than 100", wait: 10)

    fill_product_baseline
    fill_valid_properties
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "inclusion blocks value not in the allowed list" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_valid_properties
    fill_in "product[property_string_2]", with: "Invalid Option"

    click_button "Save Product"

    expect(page).to have_content("Property string 2 is not included in the list", wait: 10)

    fill_product_baseline
    fill_valid_properties
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "format blocks value not matching the regex" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_valid_properties
    fill_in "product[property_string_3]", with: "INVALID"

    click_button "Save Product"

    expect(page).to have_content("Property string 3 is invalid", wait: 10)

    fill_product_baseline
    fill_valid_properties
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end

  scenario "length blocks value shorter than minimum" do
    visit new_company_product_path(company)
    fill_product_baseline
    fill_valid_properties
    fill_in "product[property_string_4]", with: "A"

    click_button "Save Product"

    expect(page).to have_content("Property string 4 is too short (minimum is 2 characters)", wait: 10)

    fill_product_baseline
    fill_valid_properties
    click_button "Save Product"

    expect(page).to have_content("Product created successfully", wait: 10)
  end
end
