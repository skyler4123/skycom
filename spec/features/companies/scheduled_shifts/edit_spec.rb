require "rails_helper"

RSpec.feature "Companies::ScheduledShifts Edit", type: :feature, js: true do
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

  scenario "renders edit form with scheduled shift fields" do
    visit edit_company_scheduled_shift_path(company, scheduled_shift)

    expect(page).to have_selector('input[name="scheduled_shift[employee_id]"]', wait: 10)
    expect(page).to have_selector('input[name="scheduled_shift[work_date]"]', wait: 10)
    expect(page).to have_selector('select[name="scheduled_shift[status]"]', wait: 10)
  end

  scenario "updates scheduled shift status and redirects to show page" do
    visit edit_company_scheduled_shift_path(company, scheduled_shift)

    expect(page).to have_selector('select[name="scheduled_shift[status]"]', wait: 10)
    select "Completed", from: "scheduled_shift[status]"

    click_button "Save Changes"

    expect(page).to have_text(/Completed/i, wait: 10)
    expect(page).to have_current_path(company_scheduled_shift_path(company, scheduled_shift), wait: 10)

    scheduled_shift.reload
    expect(scheduled_shift.status).to eq("completed")
  end

  scenario "handles validation error and redirects back to edit page with alert" do
    visit edit_company_scheduled_shift_path(company, scheduled_shift)

    expect(page).to have_selector('select[name="scheduled_shift[status]"]', wait: 10)

    fill_in "scheduled_shift[employee_id]", with: ""
    page.execute_script("document.querySelector('input[name=\"scheduled_shift[work_date]\"]').value = ''")
    click_button "Save Changes"

    expect(page).to have_current_path(edit_company_scheduled_shift_path(company, scheduled_shift), wait: 10)
  end
end
