# spec/requests/companies/exam_assignments_controller_spec.rb
require "rails_helper"

RSpec.describe "Companies::ExamAssignmentsController", type: :request, active_job: true do
  let(:company) { create(:company) }
  let(:exam) { create(:exam, company: company) }

  before do
    exam.publish!
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def appointment(employee, status:, attempt_number: 1, score: nil, passed: nil)
    create(
      :employee_exam_appointment,
      exam: exam,
      employee: employee,
      workflow_status: status,
      attempt_number: attempt_number,
      score: score,
      passed: passed,
      started_at: status == :assigned ? nil : 1.hour.ago,
      submitted_at: [ :submitted, :graded, :expired ].include?(status) ? 30.minutes.ago : nil
    )
  end

  describe "GET #index" do
    it "returns employees with their assignment status" do
      passed_employee = create(:employee, company: company)
      failed_employee = create(:employee, company: company)
      in_progress_employee = create(:employee, company: company)
      submitted_employee = create(:employee, company: company)
      assigned_employee = create(:employee, company: company)
      expired_employee = create(:employee, company: company)
      cancelled_employee = create(:employee, company: company)

      appointment(passed_employee, status: :graded, score: 50, passed: false)
      appointment(passed_employee, status: :graded, attempt_number: 2, score: 80, passed: true)
      appointment(failed_employee, status: :graded, score: 40, passed: false)
      appointment(in_progress_employee, status: :graded, score: 40, passed: false)
      appointment(in_progress_employee, status: :in_progress, attempt_number: 2)
      appointment(submitted_employee, status: :submitted)
      appointment(assigned_employee, status: :assigned)
      appointment(expired_employee, status: :expired, score: 0, passed: false)
      appointment(cancelled_employee, status: :cancelled)

      get "/companies/#{company.id}/exams/#{exam.id}/assignments.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      by_id = body["employees"].index_by { |employee| employee["id"] }

      expect(by_id[passed_employee.id]["assignment_status"]).to eq("passed")
      expect(by_id[passed_employee.id]["best_score"].to_f).to eq(80)
      expect(by_id[passed_employee.id]["attempts_used"]).to eq(2)
      expect(by_id[failed_employee.id]["assignment_status"]).to eq("failed")
      expect(by_id[in_progress_employee.id]["assignment_status"]).to eq("in_progress")
      expect(by_id[submitted_employee.id]["assignment_status"]).to eq("submitted")
      expect(by_id[assigned_employee.id]["assignment_status"]).to eq("assigned")
      expect(by_id[expired_employee.id]["assignment_status"]).to eq("expired")
      expect(by_id[cancelled_employee.id]["assignment_status"]).to eq("not_assigned")
      expect(by_id[cancelled_employee.id]["attempts_used"]).to eq(0)
      expect(body["filters"]).to include("departments", "employee_groups", "branches")
      expect(body["pagination"]).to be_present
    end

    it "filters by search, department, employee group, and branch" do
      branch = create(:branch, company: company)
      department = create(:department, company: company)
      employee_group = create(:employee_group, company: company)
      employee = create(:employee, company: company, branch: branch, name: "Filter Target")
      DepartmentEmployeeAppointment.create!(company: company, employee: employee, department: department)
      EmployeeEmployeeGroupAppointment.create!(company: company, employee: employee, employee_group: employee_group)
      create(:employee, company: company, name: "Other Person", branch: create(:branch, company: company))

      get "/companies/#{company.id}/exams/#{exam.id}/assignments.json",
        params: { q: "Filter Target", department_id: department.id, employee_group_id: employee_group.id, branch_id: branch.id }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["employees"].map { |entry| entry["id"] }).to contain_exactly(employee.id)
    end

    it "returns 404 for another company's exam" do
      other_exam = create(:exam)

      get "/companies/#{company.id}/exams/#{other_exam.id}/assignments.json"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    it "assigns selected employees" do
      employees = create_list(:employee, 2, company: company)

      post "/companies/#{company.id}/exams/#{exam.id}/assignments.json",
        params: { employee_ids: employees.map(&:id) }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["assigned_count"]).to eq(2)
      expect(body["skipped_count"]).to eq(0)
      expect(body["message"]).to include("Assigned 2")
      expect(exam.employee_exam_appointments.where(employee: employees).count).to eq(2)
    end

    it "skips employees who already have an appointment" do
      existing = create(:employee, company: company)
      fresh = create(:employee, company: company)
      appointment(existing, status: :assigned)

      post "/companies/#{company.id}/exams/#{exam.id}/assignments.json",
        params: { employee_ids: [ existing.id, fresh.id ] }

      body = JSON.parse(response.body)
      expect(body["assigned_count"]).to eq(1)
      expect(body["skipped_count"]).to eq(1)
      expect(body["message"]).to include("1 already had an assignment")
    end

    it "ignores another company's employee" do
      valid = create(:employee, company: company)
      outsider = create(:employee)

      post "/companies/#{company.id}/exams/#{exam.id}/assignments.json",
        params: { employee_ids: [ valid.id, outsider.id ] }

      body = JSON.parse(response.body)
      expect(body["assigned_count"]).to eq(1)
      expect(exam.employee_exam_appointments.where(employee: outsider)).to be_empty
    end

    it "refuses to assign to a draft exam" do
      draft = create(:exam, company: company)
      employee = create(:employee, company: company)

      post "/companies/#{company.id}/exams/#{draft.id}/assignments.json",
        params: { employee_ids: [ employee.id ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join(" ")).to include("Publish the exam")
    end

    it "refuses an empty selection" do
      post "/companies/#{company.id}/exams/#{exam.id}/assignments.json", params: { employee_ids: [] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Select at least one employee.")
    end

    it "forbids an employee without Exam update permission" do
      employee = create(:employee, company: company)
      get sign_in_for_test_path(email: employee.user.email)

      post "/companies/#{company.id}/exams/#{exam.id}/assignments.json",
        params: { employee_ids: [ create(:employee, company: company).id ] }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
