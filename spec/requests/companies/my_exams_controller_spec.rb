# spec/requests/companies/my_exams_controller_spec.rb
require "rails_helper"

RSpec.describe "Companies::MyExamsController", type: :request, active_job: true do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:exam) { create(:exam, :published, company: company) }

  before do
    get sign_in_for_test_path(email: employee.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns published exams assigned to the employee" do
      create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)

      get "/companies/#{company.id}/my_exams.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      entry = body["exams"].find { |row| row["id"] == exam.id }
      expect(entry).to be_present
      expect(entry["attempts"]).to be_an(Array)
      expect(entry["can_start"]).to be(true)
      expect(entry["attempts_used"]).to eq(1)
      expect(entry["max_attempts"]).to eq(1)
    end

    it "keeps an in-progress attempt on an archived exam visible" do
      appointment = start_exam!(exam, employee)
      exam.archive!

      get "/companies/#{company.id}/my_exams.json"

      body = JSON.parse(response.body)
      entry = body["exams"].find { |row| row["id"] == exam.id }
      expect(entry).to be_present
      expect(entry["in_progress_appointment_id"]).to eq(appointment.id)
      expect(entry["can_start"]).to be(false)
    end

    it "does not include another employee's exams" do
      other_employee = create(:employee, company: company)
      create(:employee_exam_appointment, exam: exam, employee: other_employee, workflow_status: :assigned)

      get "/companies/#{company.id}/my_exams.json"

      body = JSON.parse(response.body)
      expect(body["exams"].map { |row| row["id"] }).not_to include(exam.id)
    end
  end

  describe "GET #show" do
    it "returns the exam and attempt history" do
      create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)

      get "/companies/#{company.id}/my_exams/#{exam.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["exam"]["id"]).to eq(exam.id)
      expect(body["attempts"].size).to eq(1)
      expect(body["can_start"]).to be(true)
    end

    it "returns 404 when the employee has no appointment for the exam" do
      get "/companies/#{company.id}/my_exams/#{exam.id}.json"

      expect(response).to have_http_status(:not_found)
    end

    it "allows a retake when attempts remain" do
      exam.update!(max_attempts: 2)
      create(
        :employee_exam_appointment,
        exam: exam,
        employee: employee,
        workflow_status: :graded,
        attempt_number: 1,
        score: 50,
        passed: false,
        started_at: 1.hour.ago,
        submitted_at: 30.minutes.ago
      )

      get "/companies/#{company.id}/my_exams/#{exam.id}.json"

      body = JSON.parse(response.body)
      expect(body["can_start"]).to be(true)
      expect(body["attempts_used"]).to eq(1)
    end

    it "does not allow a retake when the limit is reached" do
      exam.update!(max_attempts: 1)
      create(
        :employee_exam_appointment,
        exam: exam,
        employee: employee,
        workflow_status: :graded,
        attempt_number: 1,
        score: 50,
        passed: false,
        started_at: 1.hour.ago,
        submitted_at: 30.minutes.ago
      )

      get "/companies/#{company.id}/my_exams/#{exam.id}.json"

      body = JSON.parse(response.body)
      expect(body["can_start"]).to be(false)
    end
  end

  describe "POST #start" do
    it "starts an assigned attempt and returns the take URL" do
      assignment = create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)

      post "/companies/#{company.id}/my_exams/#{exam.id}/start.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["appointment_id"]).to eq(assignment.id)
      expect(body["redirect_url"]).to include("/my_exam_appointments/#{assignment.id}/take")
      expect(assignment.reload.workflow_status).to eq("in_progress")
    end

    it "returns an active attempt redirect instead of starting twice" do
      appointment = start_exam!(exam, employee)

      post "/companies/#{company.id}/my_exams/#{exam.id}/start.json"

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("You already have an attempt in progress.")
      expect(body["redirect_url"]).to include("/my_exam_appointments/#{appointment.id}/take")
    end

    it "refuses an archived exam" do
      create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)
      exam.archive!

      post "/companies/#{company.id}/my_exams/#{exam.id}/start.json"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("This exam is not available.")
    end

    it "returns 404 when the employee is not assigned" do
      post "/companies/#{company.id}/my_exams/#{exam.id}/start.json"

      expect(response).to have_http_status(:not_found)
    end
  end
end
