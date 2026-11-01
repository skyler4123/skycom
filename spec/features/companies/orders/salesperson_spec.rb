require "rails_helper"

RSpec.feature "Companies::Orders Salesperson", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:owner_employee) { company.employees.find_by(user: owner) }

  def seed_client_cache
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
      employees: [ JSON.parse(owner_employee.to_json) ]
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "new order page preselects the signed-in employee as salesperson" do
    sign_in(owner)
    seed_client_cache

    visit new_company_order_path(company)

    expect(page).to have_select("order[salesperson_id]", wait: 10)
    expect(page).to have_select("order[salesperson_id]", selected: owner_employee.name)
  end
end
