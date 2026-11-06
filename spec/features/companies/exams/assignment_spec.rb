# spec/features/companies/exams/assignment_spec.rb
require "rails_helper"

RSpec.feature "Companies::Exams assignment panel", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:exam) { create(:exam, :published, company: company, name: "Assignment exam") }
  let!(:employee_one) { create(:employee, company: company, name: "Alice Assignable") }
  let!(:employee_two) { create(:employee, company: company, name: "Bob Assignable") }

  before do
    sign_in(owner)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "categories" => company.categories.reset.map { |record| JSON.parse(record.to_json) },
      "property_mappings" => [],
      "table_configs" => [],
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

  scenario "assigns selected employees" do
    visit edit_company_exam_path(company, exam)

    expect(page).to have_content(/employees/i, wait: 10)
    within("tr", text: employee_one.name) { check }
    within("tr", text: employee_two.name) { check }
    click_button "Assign Selected"

    expect(page).to have_content("Assigned 2 employees.", wait: 10)
    within("tr", text: employee_one.name) { expect(page).to have_content("Assigned") }
    within("tr", text: employee_two.name) { expect(page).to have_content("Assigned") }
  end

  scenario "disables employees who already have an assignment" do
    create(:employee_exam_appointment, exam: exam, employee: employee_one, workflow_status: :assigned)

    visit edit_company_exam_path(company, exam)

    expect(page).to have_content(/employees/i, wait: 10)
    within("tr", text: employee_one.name) do
      expect(find("input[type='checkbox']")).to be_disabled
    end
  end

  scenario "shows a message for a draft exam" do
    draft = create(:exam, company: company, name: "Draft assignment exam")

    visit edit_company_exam_path(company, draft)

    expect(page).to have_content("This exam is not published. Publish it before assigning employees.", wait: 10)
  end
end
