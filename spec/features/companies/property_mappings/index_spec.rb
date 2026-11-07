require "rails_helper"

RSpec.feature "Companies::PropertyMappings Management", type: :feature, js: true do
  let(:branch)   { create(:branch) }
  let(:company)  { branch.company }
  let(:owner)    { company.user }
  let(:category) { create(:category, company: company, name: "Cosmetics", resource_name: "products") }

  let!(:property_mapping) do
    create(:property_mapping, company: company, category: category, name: "Cosmetics Mapping",
      metadata: { "properties" => [
        { "key" => "property_string_1", "type" => "string", "name" => "Skin Type" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Volume (ml)" }
      ] })
  end

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays table" do
    visit company_property_mappings_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('th', text: 'Name')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Resource')
    expect(page).to have_selector('th', text: 'Actions')

    expect(page).to have_selector('tbody tr', wait: 10)
    expect(page).to have_content(property_mapping.name)
  end

  scenario "edit button links to edit page" do
    visit company_property_mappings_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_property_mappings_path(company)
    expect(page).to have_selector('table', wait: 10)

    click_link property_mapping.name, match: :first
    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)
    expect(page).to have_content(property_mapping.name)
  end

  scenario "show page displays friendly property names without raw keys" do
    visit company_property_mapping_path(company, property_mapping)
    expect(page).to have_content(property_mapping.name, wait: 10)

    expect(page).to have_content(/Property Fields/i)
    expect(page).to have_content("Skin Type")
    expect(page).to have_content("Volume (ml)")
    expect(page).to have_content("Text")
    expect(page).to have_content("Whole number")
    expect(page).to have_no_content("property_string_1")
    expect(page).to have_no_content("property_integer_1")
  end

  scenario "new page creates a property mapping" do
    visit new_company_property_mapping_path(company)
    expect(page).to have_selector('form', wait: 10)

    fill_in 'property_mapping[name]', with: 'New Test Mapping'
    select category.name, from: 'property_mapping[category_id]'
    click_button 'Save Property Mapping'

    expect(page).to have_content('New Test Mapping', wait: 10)
    expect(company.property_mappings.find_by(name: 'New Test Mapping')).to be_present
  end

  scenario "edit page renders with property metadata editor" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    expect(page).to have_content("Edit Property Mapping")
    expect(page).to have_content(/Property Fields/i)

    expect(page).to have_selector('input[name*="[metadata]"][name*="[properties]"][name*="[name]"]', wait: 10)
  end

  scenario "edit adds a property field and persists to database" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    select 'Text', from: 'new-property-type'
    find('button', text: 'Add Property').click

    name_input = find(:xpath, '//input[@name="property_mapping[metadata][properties][2][name]"]', wait: 10)
    name_input.set('Texture Type')
    click_button 'Save Changes'

    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

    property_mapping.reload
    expect(property_mapping.properties.length).to eq(3)
    added = property_mapping.properties.find { |m| m['key'] == 'property_string_2' }
    expect(added).to be_present
    expect(added['name']).to eq('Texture Type')
  end

  scenario "edit page hides raw keys and shows friendly columns" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    headers = page.all('th').map(&:text)
    expect(headers).to include('Display Name', 'Type', 'Setup', 'Actions')
    expect(headers).not_to include('Key')

    expect(page).to have_no_content('property_string_1')
    expect(page).to have_no_content('property_integer_1')
    expect(page).to have_no_selector('textarea[name*="[validates]"]')
  end

  scenario "edit adds an enum property with choices and persists them" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    select 'Choice list', from: 'new-property-type'
    find('button', text: 'Add Property').click

    find(:xpath, '//input[@name="property_mapping[metadata][properties][2][name]"]', wait: 10).set('Membership tier')
    find(:xpath, '//input[@name="property_mapping[metadata][properties][2][options][0][value]"]').set('1')
    find(:xpath, '//input[@name="property_mapping[metadata][properties][2][options][0][label]"]').set('Gold')

    find('button', text: 'Add option').click

    find(:xpath, '//input[@name="property_mapping[metadata][properties][2][options][1][value]"]', wait: 10).set('2')
    find(:xpath, '//input[@name="property_mapping[metadata][properties][2][options][1][label]"]').set('Silver')

    click_button 'Save Changes'
    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

    property_mapping.reload
    added = property_mapping.properties.find { |m| m['key'] == 'property_integer_2' }
    expect(added).to be_present
    expect(added['name']).to eq('Membership tier')
    expect(added['type']).to eq('integer')
    expect(added['input_type']).to eq('select')
    expect(added['options']).to eq([
      { 'value' => 1, 'label' => 'Gold' },
      { 'value' => 2, 'label' => 'Silver' }
    ])
    expect(property_mapping.metadata['used_property_keys']).to include('property_integer_2')
  end

  scenario "edit persists advanced settings for a whole number property" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    within('[data-property-key="property_integer_1"]') do
      click_button 'Configure'
    end

    select 'Progress bar', from: 'property_mapping[metadata][properties][1][input_type]'
    fill_in 'property_mapping[metadata][properties][1][min]', with: '0'
    fill_in 'property_mapping[metadata][properties][1][max]', with: '100'
    click_button 'Save Changes'

    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

    property_mapping.reload
    entry = property_mapping.properties.find { |m| m['key'] == 'property_integer_1' }
    expect(entry['input_type']).to eq('progress_bar')
    expect(entry['min']).to eq(0)
    expect(entry['max']).to eq(100)
  end

  scenario "edit blocks a blank display name before submitting" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    select 'Text', from: 'new-property-type'
    find('button', text: 'Add Property').click
    click_button 'Save Changes'

    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}\/edit/, wait: 10)
    expect(property_mapping.reload.properties.length).to eq(2)
  end

  scenario "edit can remove every property and clears the mapping" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    first('[data-action*="removeProperty"]').click
    expect(page).to have_selector('[data-action*="removeProperty"]', wait: 10)
    first('[data-action*="removeProperty"]').click

    click_button 'Save Changes'
    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

    property_mapping.reload
    expect(property_mapping.properties).to be_blank
    expect(property_mapping.default_table_config.columns.map { |column| column['key'] }).not_to include('property_string_1', 'property_integer_1')
  end

  scenario "show page does not display custom validation rules" do
    visit company_property_mapping_path(company, property_mapping)
    expect(page).to have_content(property_mapping.name, wait: 10)

    expect(page).to have_no_content('Validates')
    expect(page).to have_no_selector('pre')
  end

  scenario "editing a property preserves settings the form does not own" do
    property_mapping.update!(metadata: { "properties" => [
      { "key" => "property_integer_1", "type" => "integer", "name" => "Tier",
        "input_type" => "select",
        "options" => [ { "value" => 1, "label" => "Gold" } ] }
    ] })

    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    fill_in "property_mapping[metadata][properties][0][name]", with: "Membership Tier"
    click_button "Save Changes"

    expect(page).to have_content("Property mapping updated successfully", wait: 10)

    property_mapping.reload
    entry = property_mapping.properties.first
    expect(entry["name"]).to eq("Membership Tier")
    expect(entry["input_type"]).to eq("select")
    expect(entry["options"]).to eq([ { "value" => 1, "label" => "Gold" } ])
  end

  describe "sync with TableConfig" do
    let(:table_config) { property_mapping.default_table_config }

    before do
      table_config.update!(metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "property_string_1", "name" => "Skin Type", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "property_integer_1", "name" => "Volume (ml)", "visible" => true, "align" => "right", "width" => nil }
      ] })
    end

    scenario "adding a field in PropertyMapping syncs to TableConfig" do
      visit edit_company_property_mapping_path(company, property_mapping)
      expect(page).to have_selector('form', wait: 10)

      page.execute_script("document.getElementById('new-property-type').value = 'boolean'")
      click_button 'Add Property'

      name_input = find(:xpath, '//input[@name="property_mapping[metadata][properties][2][name]"]', wait: 10)
      name_input.set('Active')

      click_button 'Save Changes'
      expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

      visit company_table_config_path(company, table_config)
      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_content('Active')
      expect(page).to have_no_content('property_boolean_1')

      table_config.reload
      expect(table_config.columns).to include(
        hash_including('key' => 'property_boolean_1', 'name' => 'Active')
      )
    end

    scenario "updating a field name in PropertyMapping syncs to TableConfig" do
      visit edit_company_property_mapping_path(company, property_mapping)
      expect(page).to have_selector('form', wait: 10)

      name_input = find(:xpath, '//input[@name="property_mapping[metadata][properties][0][name]"]')
      name_input.set('Skin Type Suitability')

      click_button 'Save Changes'
      expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

      visit company_table_config_path(company, table_config)
      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_content('Skin Type Suitability')
    end

    scenario "removing a field in PropertyMapping syncs to TableConfig" do
      visit edit_company_property_mapping_path(company, property_mapping)
      expect(page).to have_selector('form', wait: 10)

      first_delete = first('[data-action*="removeProperty"]')
      first_delete.click

      click_button 'Save Changes'
      expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

      visit company_table_config_path(company, table_config)
      expect(page).to have_selector('table', wait: 10)
      expect(page).not_to have_content('Skin Type')
    end
  end
end
