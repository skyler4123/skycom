require "rails_helper"

RSpec.feature "Companies::ShiftTemplates Edit", type: :feature, js: true do
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

  scenario "pre-fills form with current values" do
    visit edit_company_shift_template_path(company, shift_template)
    expect(page).to have_selector("input[name='shift_template[name]']", wait: 10)
    name_field = find("input[name='shift_template[name]']")
    expect(name_field.value).to eq(shift_template.name)
  end

  scenario "updates shift template and redirects to show page" do
    visit edit_company_shift_template_path(company, shift_template)
    expect(page).to have_selector("input[name='shift_template[name]']", wait: 10)

    fill_in "shift_template[name]", with: "Updated Shift Name"
    click_button "Save Changes"

    expect(page).to have_content("Updated Shift Name", wait: 10)
    shift_template.reload
    expect(shift_template.name).to eq("Updated Shift Name")
    expect(page).to have_current_path(company_shift_template_path(company, shift_template), wait: 10)
  end

  scenario "handles validation error and redirects back to edit page" do
    visit edit_company_shift_template_path(company, shift_template)
    expect(page).to have_selector("input[name='shift_template[name]']", wait: 10)

    fill_in "shift_template[name]", with: ""
    page.execute_script("document.querySelector('input[name=\"shift_template[start_time]\"]').value = ''")
    page.execute_script("document.querySelector('input[name=\"shift_template[end_time]\"]').value = ''")
    click_button "Save Changes"

    expect(page).to have_content("can't be blank", wait: 10)
    expect(page).to have_current_path(edit_company_shift_template_path(company, shift_template), wait: 10)
  end
end
