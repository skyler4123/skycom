RSpec.shared_examples "client cache invalidation" do |resource_name:|
  let!(:category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: resource_name)
  end

  let(:property_mapping) { category.default_property_mapping }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def seed_company_cache(company)
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(company.user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
  end

  before do
    property_mapping.update!(property_metadata: [
      { "key" => "property_string_1", "name" => "Original Field", "type" => "string", "validates" => {} }
    ])

    page.execute_script("localStorage.clear()")
    seed_company_cache(company)
    version = page.evaluate_script("document.cookie.match(/(?:^|;\\s*)client_cache_version=([^;]*)/)?.[1]")
    page.execute_script("localStorage.setItem('client_cache_version', arguments[0])", version)
  end

  def refresh_cache!(company)
    page.execute_script("localStorage.clear()")
    # Reload company data from DB and reseed
    company.reload
    company.property_mappings.reset
    company.table_configs.reset
    company.categories.reset
    seed_company_cache(company)
    version = page.evaluate_script("document.cookie.match(/(?:^|;\\s*)client_cache_version=([^;]*)/)?.[1]")
    page.execute_script("localStorage.setItem('client_cache_version', arguments[0])", version)
  end

  scenario "adding a property field appears in the dynamic table" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector("#new-property-slot", wait: 10)

    select "property_string_2 (string)", from: "new-property-slot"
    click_button "Add Property"
    fill_in "property_mapping[property_metadata][1][name]", with: "Added Field"
    click_button "Save Changes"
    expect(page).to have_content("Property mapping updated successfully", wait: 10)

    refresh_cache!(company)

    visit send("company_#{resource_name}_path", company, category_id: category.id)
    expect(page).to have_selector("th", text: "Added Field", wait: 10)
  end

  scenario "updating a property field renames the column in the dynamic table" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector("#new-property-slot", wait: 10)

    fill_in "property_mapping[property_metadata][0][name]", with: "Renamed Field"
    click_button "Save Changes"
    expect(page).to have_content("Property mapping updated successfully", wait: 10)

    refresh_cache!(company)

    visit send("company_#{resource_name}_path", company, category_id: category.id)
    expect(page).to have_selector("th", text: "Renamed Field", wait: 10)
    expect(page).not_to have_selector("th", text: "Original Field")
  end

  scenario "deleting a property field removes the column from the dynamic table" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector("#new-property-slot", wait: 10)

    find("button[data-index='0']").click
    click_button "Save Changes"
    expect(page).to have_content("Property mapping updated successfully", wait: 10)

    refresh_cache!(company)

    visit send("company_#{resource_name}_path", company, category_id: category.id)
    expect(page).not_to have_selector("th", text: "Original Field")
  end
end
