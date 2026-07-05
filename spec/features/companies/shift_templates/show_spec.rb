require "rails_helper"

RSpec.feature "Companies::ShiftTemplates Show", type: :feature, js: true do
  let(:shift_template) { create(:shift_template) }
  let(:company) { shift_template.company }
  let(:owner) { company.user }

  before do
    sign_in(owner)

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
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "displays shift template details" do
    visit company_shift_template_path(company, shift_template)
    expect(page).to have_content(shift_template.name, wait: 10)
    expect(page).to have_content(shift_template.grace_period_minutes)
    expect(page).to have_content(shift_template.unpaid_break_minutes)
  end

  scenario "has edit button linking to edit page" do
    visit company_shift_template_path(company, shift_template)
    edit_link = find("a[href*='/shift_templates/#{shift_template.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to index page" do
    visit company_shift_template_path(company, shift_template)
    back_link = find("a[href*='/shift_templates']", match: :first)
    expect(back_link).to be_present
  end
end
