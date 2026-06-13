require "rails_helper"

RSpec.feature "Companies::Products New", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:category_cosmetics) do
    Seed::CategoryService.create(
      company: company,
      name: "Cosmetics",
      resource_name: "products",
      properties: {
        "property_string_1" => "Skin Type",
        "property_string_2" => "Key Ingredients",
        "property_integer_1" => "Volume (ml)",
        "property_boolean_1" => "Organic Certified"
      }
    )
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

  scenario "renders new product form with name and type fields" do
    visit new_company_product_path(company)

    expect(page).to have_selector('input[name="product[name]"]', wait: 10)
    expect(page).to have_selector('select[name="product[business_type]"]', wait: 10)
  end

  scenario "dynamic property fields appear when category is selected" do
    visit new_company_product_path(company)

    expect(page).to have_selector('input[name="product[name]"]', wait: 10)

    select(category_cosmetics.name, from: 'product[category_id]')

    expect(page).to have_selector('input[name="product[property_string_1]"]', wait: 10)
    expect(page).to have_selector('input[name="product[property_string_2]"]')
    expect(page).to have_selector('input[name="product[property_integer_1]"]')
    expect(page).to have_selector('input[type="checkbox"][name="product[property_boolean_1]"]')
  end

  scenario "creates product and redirects to show page" do
    visit new_company_product_path(company)

    fill_in 'product[name]', with: 'New Test Product'
    select 'Digital', from: 'product[business_type]'

    click_button "Save Product"

    expect(page).to have_content('New Test Product', wait: 10)

    product = Product.find_by(name: "New Test Product")
    expect(product).to be_present
    expect(page).to have_current_path(company_product_path(company, product), wait: 10)
  end

  scenario "creates product with dynamic property values" do
    visit new_company_product_path(company)

    fill_in 'product[name]', with: 'Dynamic Product'
    select 'Digital', from: 'product[business_type]'

    select(category_cosmetics.name, from: 'product[category_id]')

    fill_in 'product[property_string_1]', with: 'Oily'
    fill_in 'product[property_integer_1]', with: '200'

    click_button "Save Product"

    expect(page).to have_content('Dynamic Product', wait: 10)

    product = Product.find_by(name: "Dynamic Product")
    expect(product).to be_present
    expect(product.category).to eq(category_cosmetics)
    expect(product.property_string_1).to eq("Oily")
    expect(product.property_integer_1).to eq(200)
  end
end
