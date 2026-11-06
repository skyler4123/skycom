# spec/requests/companies/exam_appointments_controller_spec.rb
require "rails_helper"

RSpec.describe "Companies::ExamAppointmentsController", type: :request, active_job: true do
  let(:company) { create(:company) }
  let(:exam) { create(:exam, :published, company: company) }
  let(:employee) { create(:employee, company: company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def appointment(status: :graded, score: 80, passed: true, attempt_number: 1, employee_record: employee)
    create(
      :employee_exam_appointment,
      exam: exam,
      employee: employee_record,
      workflow_status: status,
      attempt_number: attempt_number,
      score: score,
      passed: passed,
      started_at: 1.hour.ago,
      submitted_at: 30.minutes.ago,
      graded_at: status == :graded ? 20.minutes.ago : nil
    )
  end

  describe "GET #index" do
    it "lists attempts with filters and exam context" do
      passed = appointment
      failed_employee = create(:employee, company: company)
      failed = appointment(status: :graded, score: 40, passed: false, employee_record: failed_employee)

      get "/companies/#{company.id}/exams/#{exam.id}/appointments.json", params: { workflow_status: "graded" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["exam"]["id"]).to eq(exam.id)
      expect(body["appointments"].map { |entry| entry["id"] }).to include(passed.id, failed.id)
      expect(body["pagination"]).to be_present
      entry = body["appointments"].find { |row| row["id"] == passed.id }
      expect(entry["employee"]["name"]).to eq(employee.name)
      expect(entry["status"]).to eq("graded")
      expect(entry["score"].to_f).to eq(80)
    end

    it "filters by employee search" do
      target = create(:employee, company: company, name: "Target Employee")
      target_appointment = appointment(employee_record: target)
      appointment(employee_record: create(:employee, company: company, name: "Other Person"))

      get "/companies/#{company.id}/exams/#{exam.id}/appointments.json", params: { q: "Target Employee" }

      body = JSON.parse(response.body)
      expect(body["appointments"].map { |entry| entry["id"] }).to contain_exactly(target_appointment.id)
    end

    it "returns 404 for another company's exam" do
      other = create(:exam)

      get "/companies/#{company.id}/exams/#{other.id}/appointments.json"

      expect(response).to have_http_status(:not_found)
    end

    it "forbids an employee without Exam read permission" do
      get sign_in_for_test_path(email: employee.user.email)

      get "/companies/#{company.id}/exams/#{exam.id}/appointments.json"

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #show" do
    it "returns the attempt with answers and correct flags" do
      record = appointment
      question = exam.questions.first
      answer = create(
        :employee_question_appointment,
        employee_exam_appointment: record,
        question: question,
        correct: true,
        points_possible: 1,
        points_awarded: 1
      )

      get "/companies/#{company.id}/exams/#{exam.id}/appointments/#{record.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["appointment"]["id"]).to eq(record.id)
      entry = body["appointment"]["answers"].find { |row| row["id"] == answer.id }
      expect(entry["correct"]).to be(true)
      expect(entry["question"]["options"]).to include(hash_including("correct" => true))
    end
  end

  describe "PATCH #grade" do
    def submitted_text_attempt
      question = create(:question, :text, company: company, points: 2)
      text_exam = create(:exam, company: company, questions_count: 0).tap do |record|
        record.exam_question_appointments.create!(question: question, position: 0)
        record.publish!
      end
      text_appointment = start_exam!(text_exam, employee)
      answer = text_appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: text_appointment, answer_id: answer.id, text_answer: "An answer")
      Exams::SubmitAttemptService.call(appointment: text_appointment)
      [ text_exam, text_appointment.reload, answer ]
    end

    it "saves text grades and finalizes the attempt" do
      text_exam, text_appointment, answer = submitted_text_attempt

      patch "/companies/#{company.id}/exams/#{text_exam.id}/appointments/#{text_appointment.id}/grade.json",
        params: { grades: { answer.id.to_s => 2 } }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Grades saved successfully.")
      expect(body["appointment"]["status"]).to eq("graded")
      expect(body["appointment"]["score"].to_f).to eq(100)
      expect(text_appointment.reload.workflow_status).to eq("graded")
      expect(answer.reload.points_awarded).to eq(2)
    end

    it "enqueues the exam summary refresh" do
      text_exam, text_appointment, answer = submitted_text_attempt

      expect do
        patch "/companies/#{company.id}/exams/#{text_exam.id}/appointments/#{text_appointment.id}/grade.json",
          params: { grades: { answer.id.to_s => 2 } }
      end.to have_enqueued_job(Exams::SummaryJob).with(text_exam.id)
    end

    it "returns 422 when the attempt is not waiting for review" do
      record = appointment(status: :in_progress)

      patch "/companies/#{company.id}/exams/#{exam.id}/appointments/#{record.id}/grade.json",
        params: { grades: {} }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("This attempt is not waiting for review.")
    end

    it "returns 422 when a text grade is missing" do
      text_exam, text_appointment, = submitted_text_attempt

      patch "/companies/#{company.id}/exams/#{text_exam.id}/appointments/#{text_appointment.id}/grade.json",
        params: { grades: {} }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first).to include("Grade missing")
    end

    it "returns 422 when points are outside the allowed range" do
      text_exam, text_appointment, answer = submitted_text_attempt

      patch "/companies/#{company.id}/exams/#{text_exam.id}/appointments/#{text_appointment.id}/grade.json",
        params: { grades: { answer.id.to_s => 3 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first).to include("Points must be between")
    end

    it "forbids an employee without Exam update permission" do
      record = appointment(status: :submitted)
      get sign_in_for_test_path(email: employee.user.email)

      patch "/companies/#{company.id}/exams/#{exam.id}/appointments/#{record.id}/grade.json",
        params: { grades: {} }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
