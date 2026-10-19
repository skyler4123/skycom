require "rails_helper"

RSpec.feature "Skycom Index Export", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:product) do
    create(:product, company: company, name: "Export Test Product #{SecureRandom.hex(4)}", business_type: "physical")
  end

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "products")
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "products",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Product Name", "visible" => true, "align" => "left", "width" => nil }
      ] }
    )
  end

  def seed_client_cache(export_pages)
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
      employees: [],
      export_pages: export_pages
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  before do
    sign_in(owner)
  end

  scenario "shows Export button on an enabled index page" do
    seed_client_cache(EXPORT_ENABLED_RESOURCES)

    visit company_products_path(company, category_id: default_category.id)

    expect(page).to have_button("Export", wait: 10)
  end

  scenario "hides Export button when page is not enabled" do
    seed_client_cache([])

    visit company_products_path(company, category_id: default_category.id)

    expect(page).to have_selector("table", wait: 10)
    expect(page).not_to have_button("Export")
  end

  scenario "clicking Export does not crash the page" do
    seed_client_cache(EXPORT_ENABLED_RESOURCES)

    visit company_products_path(company, category_id: default_category.id)

    expect(page).to have_button("Export", wait: 10)
    click_button "Export"

    # Page should remain usable after triggering export
    expect(page).to have_selector("table", wait: 10)
  end
end
