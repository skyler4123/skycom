# spec/features/companies/exam_appointments/show_spec.rb
require "rails_helper"

RSpec.feature "Manager exam attempt grading", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:employee) { create(:employee, company: company, name: "Graded Employee") }
  let(:question) { create(:question, :text, company: company, points: 2, correct_text: "Wear protective equipment") }
  let(:exam) do
    create(:exam, company: company, questions_count: 0, name: "Grading exam").tap do |record|
      record.exam_question_appointments.create!(question: question, position: 0)
      record.publish!
    end
  end
  let!(:appointment) { start_exam!(exam, employee) }
  let!(:answer) { appointment.employee_question_appointments.first }

  before do
    Exams::SaveAnswerService.call(appointment: appointment, answer_id: answer.id, text_answer: "Wear protective equipment")
    Exams::SubmitAttemptService.call(appointment: appointment)
    appointment.reload

    sign_in(owner)
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
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: [ JSON.parse(employee.to_json) ]
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "lists submitted attempts and grades a text answer" do
    visit company_exam_appointments_path(company, exam)

    expect(page).to have_content("Graded Employee", wait: 10)
    expect(page).to have_content("Submitted")

    find("a[href='#{company_exam_appointment_path(company, exam, appointment)}']").click

    expect(page).to have_button("Save Grades", wait: 10)
    find("input[data-grade-input]").set("2")
    click_button "Save Grades"

    expect(page).to have_content("Graded", wait: 10)
    expect(page).to have_content("100.00")
    expect(page).to have_content("Correct")
  end
end
