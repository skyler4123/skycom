require "rails_helper"

RSpec.feature "Companies::PropertyMappings Management", type: :feature, js: true do
  let(:branch)   { create(:branch) }
  let(:company)  { branch.company }
  let(:owner)    { company.user }
  let(:category) { create(:category, company: company, name: "Cosmetics", resource_name: "products") }

  let!(:property_mapping) do
    create(:property_mapping, company: company, category: category, name: "Cosmetics Mapping",
      property_metadata: [
        { "key" => "property_string_1", "name" => "skin_type", "type" => "string", "label" => "Skin Type" },
        { "key" => "property_integer_1", "name" => "volume_ml", "type" => "integer", "label" => "Volume (ml)" }
      ])
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

  scenario "show page displays property metadata fields" do
    visit company_property_mapping_path(company, property_mapping)
    expect(page).to have_content(property_mapping.name, wait: 10)

    expect(page).to have_content(/Property Fields/i)
    expect(page).to have_content("property_string_1")
    expect(page).to have_content("Skin Type")
    expect(page).to have_content("property_integer_1")
    expect(page).to have_content("Volume (ml)")
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

    expect(page).to have_selector('input[name*="[property_metadata]"][name*="[name]"]', wait: 10)
  end

  scenario "edit adds a property field and persists to database" do
    visit edit_company_property_mapping_path(company, property_mapping)
    expect(page).to have_selector('form', wait: 10)

    select 'property_string_2 (string)', from: 'new-property-slot'
    find('button', text: 'Add Property').click

    name_input = find(:xpath, '//input[@name="property_mapping[property_metadata][2][name]"]', wait: 10)
    name_input.set('texture')
    label_input = find(:xpath, '//input[@name="property_mapping[property_metadata][2][label]"]')
    label_input.set('Texture Type')
    click_button 'Save Changes'

    expect(page).to have_current_path(/property_mappings\/#{property_mapping.id}$/, wait: 10)

    property_mapping.reload
    expect(property_mapping.property_metadata.length).to eq(3)
    added = property_mapping.property_metadata.find { |m| m['key'] == 'property_string_2' }
    expect(added).to be_present
    expect(added['name']).to eq('texture')
    expect(added['label']).to eq('Texture Type')
  end
end
