# spec/requests/companies/my_exam_appointments_controller_spec.rb
require "rails_helper"

RSpec.describe "Companies::MyExamAppointmentsController", type: :request, active_job: true do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:exam) { create(:exam, :published, company: company) }
  let(:appointment) { start_exam!(exam, employee) }

  before do
    get sign_in_for_test_path(email: employee.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def exam_with_question(question)
    new_exam = create(:exam, company: company, questions_count: 0)
    new_exam.exam_question_appointments.create!(question: question, position: 0)
    new_exam.publish!
    new_exam
  end

  def correct_option_id(answer)
    answer.correct_option_ids.first
  end

  describe "GET #take" do
    it "returns the attempt questions without correct answers or points" do
      get "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/take.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["questions"].size).to eq(appointment.employee_question_appointments.count)
      expect(body["remaining_seconds"]).to be > 0
      expect(body["deadline_at"]).to be_present

      question = body["questions"].first
      expect(question).not_to have_key("correct")
      expect(question).not_to have_key("points_awarded")
      expect(question["options"]).to all(satisfy { |option| !option.key?("correct") })
    end

    it "does not reset the deadline on reload" do
      get "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/take.json"
      first_deadline = JSON.parse(response.body)["deadline_at"]

      get "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/take.json"
      second_deadline = JSON.parse(response.body)["deadline_at"]

      expect(second_deadline).to eq(first_deadline)
    end

    it "redirects an assigned attempt to the exam page" do
      assigned = create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)

      get "/companies/#{company.id}/my_exam_appointments/#{assigned.id}/take.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["redirect_url"]).to include("/my_exams/#{exam.id}")
    end

    it "redirects a graded attempt to the result page" do
      answer = appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [ correct_option_id(answer) ])
      Exams::SubmitAttemptService.call(appointment: appointment)
      appointment.reload

      get "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/take.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["redirect_url"]).to include("/my_exam_appointments/#{appointment.id}")
    end

    it "expires an overdue attempt and redirects to the result" do
      travel_to(appointment.deadline_at + 1.minute) do
        get "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/take.json"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["redirect_url"]).to include("/my_exam_appointments/#{appointment.id}")
        expect(appointment.reload.workflow_status).to eq("expired")
      end
    end

    it "returns 404 for another employee's appointment" do
      other_employee = create(:employee, company: company)
      other = create(:employee_exam_appointment, exam: exam, employee: other_employee, workflow_status: :in_progress)

      get "/companies/#{company.id}/my_exam_appointments/#{other.id}/take.json"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH #answer" do
    it "saves a valid selection" do
      answer = appointment.employee_question_appointments.first
      option_id = answer.snapshot_options.first["id"]

      patch "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/answer.json",
        params: { answer_id: answer.id, selected_option_ids: [ option_id ] }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["saved"]).to be(true)
      expect(body["answered_count"]).to eq(1)
      expect(answer.reload.selected_option_ids).to eq([ option_id ])
    end

    it "rejects an option outside the snapshot" do
      answer = appointment.employee_question_appointments.first

      patch "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/answer.json",
        params: { answer_id: answer.id, selected_option_ids: [ SecureRandom.uuid ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Selected option does not belong to this question.")
    end

    it "rejects answers after the deadline" do
      answer = appointment.employee_question_appointments.first

      travel_to(appointment.deadline_at + 1.minute) do
        patch "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/answer.json",
          params: { answer_id: answer.id, selected_option_ids: [] }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["errors"]).to include("Time is up.")
      end
    end

    it "returns 404 for another employee's appointment" do
      other_employee = create(:employee, company: company)
      other = create(:employee_exam_appointment, exam: exam, employee: other_employee, workflow_status: :in_progress)

      patch "/companies/#{company.id}/my_exam_appointments/#{other.id}/answer.json",
        params: { answer_id: SecureRandom.uuid, selected_option_ids: [] }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #submit" do
    it "grades an objective-only attempt" do
      answer = appointment.employee_question_appointments.first

      post "/companies/#{company.id}/my_exam_appointments/#{appointment.id}/submit.json",
        params: { answers: [ { id: answer.id, selected_option_ids: [ correct_option_id(answer) ] } ] }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["appointment"]["status"]).to eq("graded")
      expect(body["appointment"]["score"].to_f).to eq(100)
      expect(body["redirect_url"]).to include("/my_exam_appointments/#{appointment.id}")
      expect(appointment.reload.workflow_status).to eq("graded")
    end

    it "marks a text attempt as submitted for review" do
      question = create(:question, :text, company: company)
      text_exam = exam_with_question(question)
      text_appointment = start_exam!(text_exam, employee)
      text_answer = text_appointment.employee_question_appointments.first

      post "/companies/#{company.id}/my_exam_appointments/#{text_appointment.id}/submit.json",
        params: { answers: [ { id: text_answer.id, text_answer: "An answer" } ] }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["appointment"]["status"]).to eq("submitted")
      expect(body["message"]).to include("waiting for review")
      expect(text_appointment.reload.score).to be_nil
    end

    it "expires a submission after the grace period" do
      exam.update!(duration_minutes: 1)
      expiring = start_exam!(exam.reload, employee)

      travel_to(expiring.deadline_at + Exams::SubmitAttemptService::GRACE_PERIOD + 1.second) do
        post "/companies/#{company.id}/my_exam_appointments/#{expiring.id}/submit.json"

        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["errors"]).to include("Time is up. The exam was submitted automatically.")
        expect(body["redirect_url"]).to include("/my_exam_appointments/#{expiring.id}")
        expect(expiring.reload.workflow_status).to eq("expired")
      end
    end

    it "returns 404 for another employee's appointment" do
      other_employee = create(:employee, company: company)
      other = create(:employee_exam_appointment, exam: exam, employee: other_employee, workflow_status: :in_progress)

      post "/companies/#{company.id}/my_exam_appointments/#{other.id}/submit.json"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #show (result)" do
    it "returns pending review without correct answers" do
      question = create(:question, :text, company: company)
      text_exam = exam_with_question(question)
      text_appointment = start_exam!(text_exam, employee)
      text_answer = text_appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: text_appointment, answer_id: text_answer.id, text_answer: "An answer")
      Exams::SubmitAttemptService.call(appointment: text_appointment)

      get "/companies/#{company.id}/my_exam_appointments/#{text_appointment.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["appointment"]["status"]).to eq("submitted")
      expect(body["answers"].first).not_to have_key("correct")
      expect(body["answers"].first).not_to have_key("points_awarded")
      expect(body["answers"].first["question"]["options"]).to all(satisfy { |option| !option.key?("correct") })
    end

    it "returns correct answers after grading" do
      answer = appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [ correct_option_id(answer) ])
      Exams::SubmitAttemptService.call(appointment: appointment)
      appointment.reload

      get "/companies/#{company.id}/my_exam_appointments/#{appointment.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["appointment"]["status"]).to eq("graded")
      expect(body["answers"].first["correct"]).to be(true)
      expect(body["answers"].first["question"]["options"]).to include(hash_including("correct" => true))
    end

    it "returns 404 for another employee's appointment" do
      other_employee = create(:employee, company: company)
      other = create(:employee_exam_appointment, exam: exam, employee: other_employee, workflow_status: :graded)

      get "/companies/#{company.id}/my_exam_appointments/#{other.id}.json"

      expect(response).to have_http_status(:not_found)
    end
  end
end
