require "rails_helper"

RSpec.feature "Companies::ScheduledShifts Show", type: :feature, js: true do
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

  scenario "displays scheduled shift details" do
    visit company_scheduled_shift_path(company, scheduled_shift)

    expect(page).to have_content(employee.name, wait: 10)
    expect(page).to have_text(/Scheduled/i, wait: 10)
  end

  scenario "has edit button linking to edit page" do
    visit company_scheduled_shift_path(company, scheduled_shift)

    edit_link = find("a[href*='/scheduled_shifts/#{scheduled_shift.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to scheduled shifts index" do
    visit company_scheduled_shift_path(company, scheduled_shift)

    back_link = find("a[href*='/scheduled_shifts']", match: :first)
    expect(back_link).to be_present
  end
end
