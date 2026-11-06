# spec/features/companies/my_exams/index_spec.rb
require "rails_helper"

RSpec.feature "Employee My Exams", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company, name: "Exam Taker") }
  let(:question) do
    create(
      :question,
      company: company,
      name: "What is 2 + 2?",
      options: [
        { content: "3", correct: false },
        { content: "4", correct: true }
      ]
    )
  end
  let(:exam) do
    create(:exam, company: company, questions_count: 0, name: "Safety exam", max_attempts: 2).tap do |record|
      record.exam_question_appointments.create!(question: question, position: 0)
      record.publish!
    end
  end
  let!(:assignment) { create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned) }

  before do
    sign_in(employee.user)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "categories" => company.categories.reset.map { |record| JSON.parse(record.to_json) },
      "property_mappings" => [],
      "table_configs" => [],
      "branches" => company.branches.reset.map { |record| JSON.parse(record.to_json) },
      "departments" => [],
      "roles" => []
    )
    payload = {
      user: JSON.parse(employee.user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: [ JSON.parse(employee.to_json) ]
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "shows the assigned exam in To Do" do
    visit company_my_exams_path(company)

    expect(page).to have_content("Safety exam", wait: 10)
    expect(page).to have_button("Start Exam")
    expect(page).to have_content("To Do")
  end

  scenario "takes an exam, autosaves, submits, and shows the result" do
    visit company_my_exams_path(company)
    find("button[data-exam-id='#{exam.id}']").click

    expect(page).to have_content("What is 2 + 2?", wait: 10)
    find("input[type='radio'][value='#{question.correct_option.id}']").choose
    expect(page).to have_content("Saved", wait: 10)
    page.refresh

    expect(page).to have_selector("input[type='radio'][value='#{question.correct_option.id}']:checked", wait: 10)
    click_button "Submit Exam"
    find(".swal2-confirm").click

    expect(page).to have_content("Passed", wait: 10)
    expect(page).to have_content("100.00")
  end

  scenario "shows pending review for a text answer" do
    text_question = create(
      :question,
      :text,
      company: company,
      name: "Explain safety",
      correct_text: "Wear protective equipment"
    )
    text_exam = create(:exam, company: company, questions_count: 0, name: "Text safety exam").tap do |record|
      record.exam_question_appointments.create!(question: text_question, position: 0)
      record.publish!
    end
    create(:employee_exam_appointment, exam: text_exam, employee: employee, workflow_status: :assigned)

    visit company_my_exams_path(company)
    find("button[data-exam-id='#{text_exam.id}']").click

    expect(page).to have_content("Explain safety", wait: 10)
    find("textarea").set("Wear protective equipment")
    click_button "Submit Exam"
    find(".swal2-confirm").click

    expect(page).to have_content("Pending review", wait: 10)
    expect(page).to have_content("waiting for a manager")
  end

  scenario "offers a retake after a graded attempt" do
    assignment.update!(
      workflow_status: :graded,
      score: 50,
      passed: false,
      started_at: 1.hour.ago,
      submitted_at: 30.minutes.ago,
      graded_at: 20.minutes.ago
    )

    visit company_my_exam_path(company, exam)

    expect(page).to have_content("Retake", wait: 10)
    click_button "Retake"
    expect(page).to have_content("What is 2 + 2?", wait: 10)
  end
end
