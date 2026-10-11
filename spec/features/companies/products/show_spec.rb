require "rails_helper"

RSpec.feature "Companies::Products Show", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:product) do
    create(:product,
      company: company,
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
    names = Array.new(2) { "Product-#{SecureRandom.hex(8)}" }
    names.map.with_index do |nm, i|
      product = Product.new(
        company: company,
        name: nm,
        description: Faker::Lorem.sentence(word_count: 12),
        code: "PRD-#{SecureRandom.hex(4).upcase}",
        category: category_cosmetics,
        property_mapping: category_cosmetics.default_property_mapping,
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
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "displays product name and description" do
    visit company_product_path(company, product)

    expect(page).to have_content(product.name, wait: 10)
    expect(page).to have_content(product.description, wait: 10)
  end

  scenario "displays all standard product fields" do
    visit company_product_path(company, product)

    expect(page).to have_content(product.name, wait: 10)
    expect(page).to have_content(product.code, wait: 10)
  end

  scenario "displays dynamic property labels" do
    target = products_cosmetics.first
    visit company_product_path(company, target)

    expect(page).to have_content('Skin Type', wait: 10)
    expect(page).to have_content('Key Ingredients', wait: 10)
    expect(page).to have_content('Volume (ml)', wait: 10)
    expect(page).to have_content('Organic Certified', wait: 10)
  end

  scenario "displays stocks of this product" do
    warehouse_a = create(:warehouse, company: company, name: "PRD Show WH A #{SecureRandom.hex(3)}")
    warehouse_b = create(:warehouse, company: company, name: "PRD Show WH B #{SecureRandom.hex(3)}")
    Stock.create!(company: company, warehouse: warehouse_a, product: product, quantity: 12, pending: 3, name: "PRD Show SA", code: "STK-PRDS-A-#{SecureRandom.hex(2).upcase}")
    Stock.create!(company: company, warehouse: warehouse_b, product: product, quantity: 4, pending: 0, name: "PRD Show SB", code: "STK-PRDS-B-#{SecureRandom.hex(2).upcase}")
    other_product = create(:product, company: company, name: "Other Shown Product #{SecureRandom.hex(3)}")
    Stock.create!(company: company, warehouse: warehouse_a, product: other_product, quantity: 99, pending: 0, name: "PRD Show Other", code: "STK-PRDS-O-#{SecureRandom.hex(2).upcase}")

    visit company_product_path(company, product)

    expect(page).to have_content("Stocks of this product", wait: 10)
    expect(page).to have_content(warehouse_a.name, wait: 10)
    expect(page).to have_content(warehouse_b.name, wait: 10)
  end
end
