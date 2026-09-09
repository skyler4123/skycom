require "rails_helper"

RSpec.feature "Companies::StockImports Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  # The index defaults to the FIRST category of this resource (defaultFilterCategory);
  # pin records + visit to this category and seed a full TableConfig so columns are stable
  # whether or not the (random) company business_type triggered init seeding.
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stock_imports") }

  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "stock_imports",
      metadata: { "columns" => [
        { "key" => "code", "name" => "Code", "visible" => true },
        { "key" => "name", "name" => "Name", "visible" => true },
        { "key" => "product_name", "name" => "Product", "visible" => true },
        { "key" => "category_name", "name" => "Category", "visible" => true },
        { "key" => "from_name", "name" => "From", "visible" => true },
        { "key" => "to_name", "name" => "To", "visible" => true },
        { "key" => "quantity", "name" => "Quantity", "visible" => true },
        { "key" => "business_type", "name" => "Type", "visible" => true },
        { "key" => "workflow_status", "name" => "Status", "visible" => true }
      ] })
  end


  let(:warehouse) do
    Seed::WarehouseService.create(
      company: company,
      branch: branch,
      name: "Test Warehouse"
    )
  end

  let(:product) do
    Seed::ProductService.create(
      company: company,
      name: "Test Product"
    )
  end

  let!(:import1) do
    Seed::StockImportService.create(
      company: company,
      category: category,
      warehouse: warehouse,
      product: product,
      branch: branch,
      code: "STKIM001",
      quantity: 50,
      business_type: "purchase",
      workflow_status: "completed"
    )
  end

  let!(:import2) do
    Seed::StockImportService.create(
      company: company,
      category: category,
      warehouse: warehouse,
      product: product,
      branch: branch,
      code: "STKIM002",
      quantity: 25,
      business_type: "return",
      workflow_status: "pending"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays stock imports table" do
    visit company_stock_imports_path(company, category_id: category.id)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Code')
    expect(page).to have_selector('th', text: 'Product')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'From')
    expect(page).to have_selector('th', text: 'To')
    expect(page).to have_selector('th', text: 'Quantity')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
  end

  scenario "display stock import data in table" do
    visit company_stock_imports_path(company, category_id: category.id)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("STKIM001")
    expect(page).to have_content("Test Product")
    expect(page).to have_content(50)
  end

  scenario "display business type as badge" do
    visit company_stock_imports_path(company, category_id: category.id)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Purchase")
    expect(page).to have_content("Return")
  end

  scenario "display workflow status as badge" do
    visit company_stock_imports_path(company, category_id: category.id)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
