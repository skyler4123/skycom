require "rails_helper"

RSpec.feature "Companies::ScheduledShifts Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }

  let!(:scheduled_shift) do
    create(:scheduled_shift, company: company, branch: branch, employee: employee)
  end

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

  scenario "index page loads and displays scheduled shifts table" do
    visit company_scheduled_shifts_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Employee")
    expect(page).to have_selector("th", text: "Status")
    expect(page).to have_selector("tbody tr", wait: 10)
  end

  scenario "employee name links to show page" do
    visit company_scheduled_shifts_path(company)
    expect(page).to have_selector("table", wait: 10)

    link = find("a[href*='/scheduled_shifts/#{scheduled_shift.id}']", match: :first)
    expect(link).to be_present
  end

  scenario "add button links to new scheduled shift page" do
    visit company_scheduled_shifts_path(company)
    expect(page).to have_link(href: new_company_scheduled_shift_path(company), wait: 10)
  end

  scenario "edit button links to edit page for each shift" do
    visit company_scheduled_shifts_path(company)
    expect(page).to have_selector("table", wait: 10)

    edit_link = find("a[href*='/scheduled_shifts/#{scheduled_shift.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end
end
