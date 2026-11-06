# spec/features/companies/exams/index_spec.rb
require "rails_helper"

RSpec.feature "Companies::Exams Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:category) { create(:category, company: company, resource_name: "questions", name: "General") }
  let!(:question) { create(:question, company: company, category: category, name: "Safety question") }
  let!(:exam) { create(:exam, company: company, name: "Safety exam") }

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

  scenario "index lists exams with status" do
    visit company_exams_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Safety exam")
    expect(page).to have_content("Draft")
    expect(page).to have_link("Add Exam")
  end

  scenario "creates an exam with a selected question" do
    visit new_company_exam_path(company)

    expect(page).to have_selector("form", wait: 10)
    fill_in "exam[name]", with: "New safety exam"
    fill_in "exam[duration_minutes]", with: "30"
    fill_in "exam[passing_score]", with: "75"
    find("input[data-question-id='#{question.id}']").check
    click_button "Create Exam"

    expect(page).to have_current_path(%r{/exams/[^/]+$}, wait: 10)
    expect(page).to have_content("New safety exam")
    expect(page).to have_content("Safety question")
  end

  scenario "publishes a draft exam" do
    visit company_exam_path(company, exam)

    expect(page).to have_button("Publish", wait: 10)
    click_button "Publish"

    expect(page).to have_content("Published", wait: 10)
    expect(page).to have_button("Archive")
  end

  scenario "edits an exam" do
    visit edit_company_exam_path(company, exam)

    expect(page).to have_selector("form", wait: 10)
    fill_in "exam[name]", with: "Updated safety exam"
    fill_in "exam[duration_minutes]", with: "45"
    click_button "Save Changes"

    expect(page).to have_current_path(company_exam_path(company, exam), wait: 10)
    expect(page).to have_content("Updated safety exam")
  end

  scenario "shows the background summary on the exam page" do
    create(
      :exam_summary,
      exam: exam,
      assigned_count: 2,
      started_count: 2,
      submitted_count: 2,
      graded_count: 2,
      passed_count: 1,
      failed_count: 1,
      pass_rate: 50,
      average_score: 70,
      highest_score: 90,
      lowest_score: 50,
      computed_at: Time.current
    )

    visit company_exam_path(company, exam)

    expect(page).to have_content(/exam summary/i, wait: 10)
    expect(page).to have_content("50.00%")
    expect(page).to have_content(/assigned/i)
    expect(page).to have_button("Refresh Summary")
  end
end
