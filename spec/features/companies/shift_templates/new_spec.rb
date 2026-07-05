require "rails_helper"

RSpec.feature "Companies::ShiftTemplates New", type: :feature, js: true do
  let(:company) { create(:company) }
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

  scenario "creates shift template and redirects to show page" do
    visit new_company_shift_template_path(company)
    expect(page).to have_selector("input[name='shift_template[name]']", wait: 10)

    fill_in "shift_template[name]", with: "Night Shift"
    page.execute_script("document.querySelector('input[name=\"shift_template[start_time]\"]').value = '23:00'")
    page.execute_script("document.querySelector('input[name=\"shift_template[end_time]\"]').value = '07:00'")
    click_button "Save"

    expect(page).to have_content("Night Shift", wait: 10)
    record = ShiftTemplate.find_by(name: "Night Shift")
    expect(record).to be_present
    expect(page).to have_current_path(company_shift_template_path(company, record), wait: 10)
  end

  scenario "handles validation error" do
    visit new_company_shift_template_path(company)
    expect(page).to have_selector("input[name='shift_template[name]']", wait: 10)

    fill_in "shift_template[name]", with: ""
    page.execute_script("document.querySelector('input[name=\"shift_template[start_time]\"]').value = ''")
    page.execute_script("document.querySelector('input[name=\"shift_template[end_time]\"]').value = ''")
    click_button "Save"

    expect(page).to have_current_path(new_company_shift_template_path(company), wait: 10)
  end
end
