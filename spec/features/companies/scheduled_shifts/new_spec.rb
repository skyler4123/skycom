require "rails_helper"

RSpec.feature "Companies::ScheduledShifts New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }

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
      enums: {
        scheduled_shift: {
          statuses: [
            { name: "Scheduled", value: "scheduled" },
            { name: "Active", value: "active" },
            { name: "Completed", value: "completed" },
            { name: "Cancelled", value: "cancelled" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders new scheduled shift form with all required fields" do
    visit new_company_scheduled_shift_path(company)

    expect(page).to have_selector('input[name="scheduled_shift[employee_id]"]', wait: 10)
    expect(page).to have_selector('input[name="scheduled_shift[work_date]"]', wait: 10)
    expect(page).to have_selector('input[name="scheduled_shift[expected_start_at]"]', wait: 10)
    expect(page).to have_selector('input[name="scheduled_shift[expected_end_at]"]', wait: 10)
    expect(page).to have_selector('select[name="scheduled_shift[status]"]', wait: 10)
  end

  scenario "creates scheduled shift and redirects to show page" do
    visit new_company_scheduled_shift_path(company)

    fill_in "scheduled_shift[employee_id]", with: employee.id
    fill_in "scheduled_shift[expected_start_at]", with: Time.current.change(hour: 9).strftime("%Y-%m-%dT%H:%M")
    fill_in "scheduled_shift[expected_end_at]", with: Time.current.change(hour: 18).strftime("%Y-%m-%dT%H:%M")
    fill_in "scheduled_shift[work_date]", with: Date.current.iso8601
    select "Scheduled", from: "scheduled_shift[status]"

    click_button "Save"

    expect(page).to have_content("Scheduled Shift", wait: 10)
    expect(page).to have_current_path(/\/scheduled_shifts\//, wait: 10)
  end

  scenario "shows validation error when required fields are missing" do
    visit new_company_scheduled_shift_path(company)

    click_button "Save"

    expect(page).to have_current_path(new_company_scheduled_shift_path(company), wait: 10)
  end
end
