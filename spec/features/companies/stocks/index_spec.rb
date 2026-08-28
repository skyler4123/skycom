require "rails_helper"

RSpec.feature "Companies::Stocks Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let(:warehouse) do
    Seed::WarehouseService.create(
      company: company,
      branch: branch
    )
  end

  let(:product) do
    Seed::ProductService.create(
      company: company,
      name: "Test Product"
    )
  end

  let(:product2) do
    Seed::ProductService.create(
      company: company,
      name: "Low Stock Product"
    )
  end

  let!(:stock) do
    Seed::StockService.create(
      warehouse: warehouse,
      product_id: product.id,
      company: company,
      branch: branch,
      business_type: "inventory",
      workflow_status: "confirmed"
    )
  end

  let!(:low_stock) do
    Seed::StockService.create(
      warehouse: warehouse,
      product_id: product2.id,
      company: company,
      branch: branch,
      business_type: "finished_good",
      workflow_status: "confirmed"
    )
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays stocks table" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Product')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Warehouse')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
  end

  scenario "display stock data in table" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Test Product")
    expect(page).to have_content(warehouse.name)
  end

  scenario "display business type as badge" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content("Inventory")
    expect(page).to have_content("Finished_good")
  end

  scenario "display workflow status as badge" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "display stock with workflow status" do
    visit company_stocks_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  # ============================================================================
  # Branch Filter Tests
  # ============================================================================
  describe "branch filter" do
    let(:branch2) { create(:branch, company: company) }

    let(:warehouse2) do
      Seed::WarehouseService.create(company: company, branch: branch2)
    end

    let(:product3) do
      Seed::ProductService.create(
        company: company,
        name: "Branch Two Product"
      )
    end

    let!(:stock_branch2) do
      Seed::StockService.create(
        warehouse: warehouse2,
        product_id: product3.id,
        company: company,
        branch: branch2,
        business_type: "inventory",
        workflow_status: "confirmed"
      )
    end

    before do
      page.execute_script("localStorage.clear()")

      company_data = JSON.parse(company.to_json).merge(
        "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
        "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
        "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
        "branches" => company.branches.map { |b| JSON.parse(b.to_json) },
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

    scenario "shows branch dropdown with All Branches and branch options" do
      visit company_stocks_path(company)

      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_selector('select[name="branch_id"]')
      expect(page).to have_selector('option', text: 'All Branches')
      expect(page).to have_selector('option', text: branch.name)
      expect(page).to have_selector('option', text: branch2.name)
    end

    scenario "defaults to All Branches showing all stocks" do
      visit company_stocks_path(company)

      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_content("Test Product", wait: 5)
      expect(page).to have_content("Branch Two Product", wait: 5)
    end

    scenario "filters by branch and updates URL" do
      visit company_stocks_path(company)
      expect(page).to have_selector('table', wait: 10)

      select(branch2.name, from: 'branch_id')
      click_button "Search"

      expect(page).to have_current_path(/branch_id=#{branch2.id}/)
      expect(page).to have_selector('tbody tr', wait: 10)
      expect(page).to have_content("Branch Two Product", wait: 5)
      expect(page).not_to have_content("Test Product")
    end
  end
end
