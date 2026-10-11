require "rails_helper"

RSpec.feature "Companies::Warehouses Show stocks", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

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

  scenario "displays stocks belonging to this warehouse" do
    product_a = create(:product, company: company, name: "WH Show Product A #{SecureRandom.hex(3)}")
    product_b = create(:product, company: company, name: "WH Show Product B #{SecureRandom.hex(3)}")
    Stock.create!(company: company, warehouse: warehouse, product: product_a, quantity: 10, pending: 2, name: "WH Show SA", code: "STK-WHS-A-#{SecureRandom.hex(2).upcase}")
    Stock.create!(company: company, warehouse: warehouse, product: product_b, quantity: 5, pending: 0, name: "WH Show SB", code: "STK-WHS-B-#{SecureRandom.hex(2).upcase}")
    other_warehouse = create(:warehouse, company: company)
    other_product = create(:product, company: company, name: "WH Show Other #{SecureRandom.hex(3)}")
    Stock.create!(company: company, warehouse: other_warehouse, product: other_product, quantity: 99, pending: 0, name: "WH Show Other", code: "STK-WHS-O-#{SecureRandom.hex(2).upcase}")

    visit company_warehouse_path(company, warehouse)

    expect(page).to have_content("Stocks in this warehouse", wait: 10)
    expect(page).to have_content(product_a.name, wait: 10)
    expect(page).to have_content(product_b.name, wait: 10)
    expect(page).not_to have_content(other_product.name)
  end
end
