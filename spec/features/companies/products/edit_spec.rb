require "rails_helper"

RSpec.feature "Companies::Products Edit", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:product) do
    create(:product,
      company: company,
      name: "Editable Product",
      description: "Original description",
      business_type: "physical"
    )
  end

  let(:category_cosmetics) do
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

  let!(:products_cosmetics) do
    names = [ "Gorgeous Steel Plate", "Practical Wool Shoes" ]
    names.map.with_index do |nm, i|
      product = Product.new(
        company: company,
        name: nm,
        description: Faker::Lorem.sentence(word_count: 12),
        code: "PRD-#{SecureRandom.hex(4).upcase}",
        category: category_cosmetics,
        property_mapping: category_cosmetics.property_mapping,
        business_type: Product.business_types.keys.sample,
        workflow_status: Product.workflow_statuses.keys.sample,
        lifecycle_status: Product.lifecycle_statuses.keys.sample
      )
      Seed::PropertyPopulator.populate(product)
      product.save!
      product
    end
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
          workflow_statuses: [
            { name: "Active", value: "active" },
            { name: "Inactive", value: "inactive" },
            { name: "Draft", value: "draft" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders edit form with product name and type pre-filled" do
    visit edit_company_product_path(company, product)

    expect(page).to have_selector('input[name="product[name]"]', wait: 10)
    expect(page).to have_selector('select[name="product[business_type]"]', wait: 10)
    expect(page).to have_selector('select[name="product[workflow_status]"]', wait: 10)
  end

  scenario "dynamic property fields appear when product has a category" do
    target = products_cosmetics.first
    visit edit_company_product_path(company, target)

    expect(page).to have_selector('input[name="product[property_string_1]"]', wait: 10)
    expect(page).to have_selector('input[name="product[property_string_2]"]')
    expect(page).to have_selector('input[name="product[property_integer_1]"]')
    expect(page).to have_selector('input[type="checkbox"][name="product[property_boolean_1]"]')
  end

  scenario "updates product and redirects to show page" do
    visit edit_company_product_path(company, product)

    expect(page).to have_selector('input[name="product[name]"]', wait: 10)
    fill_in 'product[name]', with: 'Updated Product Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Product Name', wait: 10)

    product.reload
    expect(product.name).to eq("Updated Product Name")
    expect(page).to have_current_path(company_product_path(company, product), wait: 10)
  end

  scenario "handles validation error and redirects back to edit page with alert" do
    visit edit_company_product_path(company, product)

    expect(page).to have_selector('input[name="product[name]"]', wait: 10)
    fill_in 'product[name]', with: ''

    click_button "Save Changes"

    expect(page).to have_content("can't be blank", wait: 10)
    expect(page).to have_current_path(edit_company_product_path(company, product), wait: 10)
  end
end
