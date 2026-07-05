require "rails_helper"

RSpec.feature "Companies::ShiftTemplates Management", type: :feature, js: true do
  let(:shift_template) { create(:shift_template) }
  let(:company) { shift_template.company }
  let(:owner) { company.user }

  let!(:shift_template2) { create(:shift_template, company: company) }

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

  scenario "index page loads and displays shift templates table" do
    visit company_shift_templates_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Name")
    expect(page).to have_selector("tbody tr")
    expect(page).to have_content(shift_template.name)
  end

  scenario "shift template name links to show page" do
    visit company_shift_templates_path(company)
    expect(page).to have_selector("table", wait: 10)
    link = find("a[href*='/shift_templates/#{shift_template.id}']", match: :first)
    expect(link).to be_present
  end

  scenario "edit button links to edit page" do
    visit company_shift_templates_path(company)
    expect(page).to have_selector("table", wait: 10)
    edit_link = find("a[href*='/shift_templates/#{shift_template.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "add button links to new page" do
    visit company_shift_templates_path(company)
    expect(page).to have_link("Add", href: new_company_shift_template_path(company), wait: 10)
  end
end
