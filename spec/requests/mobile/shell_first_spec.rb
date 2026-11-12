# frozen_string_literal: true

require "rails_helper"

# Proves the Shell-First contract for every mobile page: the HTML response is
# only a mount div (data-controller + data-json-url) and the same URL with
# .json returns the screen payload. Page content lives in the Stimulus
# controller, never in the HTML response.
RSpec.describe "Mobile Shell-First", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:employee) { company.employees.find_by(user: user) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: user.email) }

  describe "notifications" do
    it "renders only the shell" do
      get mobile_company_notifications_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="mobile--companies--notifications--index"')
      expect(response.body).to include(
        %(data-json-url="#{mobile_company_notifications_path(company, format: :json)}")
      )
      expect(response.body).not_to include("You have no notifications right now.")
    end

    it "returns the payload as JSON" do
      get mobile_company_notifications_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("company", "id")).to eq(company.id)
      expect(json.dig("employee", "name")).to eq(employee.name)
      expect(json["notifications"]).to eq([])
    end
  end

  describe "operations" do
    let!(:branch) { create(:branch, company: company, name: "Downtown Branch") }
    let!(:operation_record) do
      create(:operation, company: company, branch: branch, name: "Front Counter", operation_type: :pos)
    end

    it "renders only the shell" do
      get mobile_company_operations_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="mobile--companies--operations--index"')
      expect(response.body).to include(
        %(data-json-url="#{mobile_company_operations_path(company, format: :json)}")
      )
      expect(response.body).not_to include("Front Counter")
    end

    it "returns accessible appointments as JSON" do
      other_company = create(:company)
      create(
        :operation,
        company: other_company,
        branch: create(:branch, company: other_company),
        name: "Other Company Operation"
      )

      get mobile_company_operations_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("company", "id")).to eq(company.id)
      expect(json["appointments"].size).to eq(1)

      row = json["appointments"].first
      expect(row.dig("operation", "name")).to eq("Front Counter")
      expect(row.dig("operation", "code")).to eq(operation_record.code)
      expect(row.dig("operation", "operation_type")).to eq("pos")
      expect(row.dig("operation", "workflow_status")).to eq("approved")
      expect(row["location_type"]).to eq("branch")
      expect(row.dig("location", "name")).to eq("Downtown Branch")
      expect(row["appointment_workflow_status"]).to eq("active")
    end
  end
  describe "attendance month" do
    let(:month) { Date.current.beginning_of_month }
    let!(:attendance_month) do
      AttendanceMonth.create!(
        company: company,
        employee: employee,
        month: month,
        total_work_minutes: 9_600,
        total_present_days: 20,
        total_absent_days: 2,
        total_records: 22,
        total_overtime_minutes: 270
      )
    end
    let!(:attendance_day) do
      AttendanceDay.create!(
        company: company,
        employee: employee,
        attendance_date: month + 2.days,
        attendance_status: :present,
        total_seconds_worked: 28_800,
        check_in: (month + 2.days).in_time_zone.change(hour: 9, min: 0),
        check_out: (month + 2.days).in_time_zone.change(hour: 17, min: 0)
      )
    end

    it "renders only the shell" do
      get mobile_company_attendance_month_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="mobile--companies--attendance-months--show"')
      expect(response.body).to include(
        %(data-json-url="#{mobile_company_attendance_month_path(company, format: :json)}")
      )
      expect(response.body).not_to include("Total Worked")
    end

    it "returns the month summary and days as JSON" do
      get mobile_company_attendance_month_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("employee", "name")).to eq(employee.name)
      expect(json.dig("attendance_month", "total_work_minutes")).to eq(9_600)
      expect(json.dig("attendance_month", "total_present_days")).to eq(20)
      expect(json["attendance_days"].size).to eq(1)
      expect(json["attendance_days"].first["attendance_status"]).to eq("present")
      expect(json["attendance_days"].first["total_seconds_worked"]).to eq(28_800)
      expect(json["month"]).to eq(month.iso8601)
      expect(json["next_disabled"]).to be(true)
      expect(json["prev_month"]).to eq((month - 1.month).strftime("%Y-%m"))
    end

    it "returns a past month when given ?month" do
      previous = month - 1.month
      get mobile_company_attendance_month_path(company, format: :json, month: previous.strftime("%Y-%m"))

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["month"]).to eq(previous.iso8601)
      expect(json["attendance_month"]).to be_nil
      expect(json["next_disabled"]).to be(false)
    end
  end

  describe "employee profile" do
    let!(:manager) { create(:employee, company: company, name: "Morgan Manager") }
    let!(:employee_group) do
      create(:employee_group, company: company, manager: manager, name: "Clinical Team")
    end

    before do
      employee.update!(expiration_date: Date.new(2026, 11, 30))
      create(
        :employee_employee_group_appointment,
        company: company,
        employee: employee,
        employee_group: employee_group
      )
    end

    it "renders only the shell" do
      get mobile_company_employee_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="mobile--companies--employees--show"')
      expect(response.body).to include(
        %(data-json-url="#{mobile_company_employee_path(company, format: :json)}")
      )
      expect(response.body).not_to include("Account &amp; Contact")
    end

    it "returns the profile payload as JSON" do
      get mobile_company_employee_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("employee", "name")).to eq(employee.name)
      expect(json.dig("employee", "business_type")).to eq(employee.business_type)
      expect(json.dig("employee", "email")).to eq(employee.email)
      expect(json.dig("employee", "expiration_date")).to eq("2026-11-30")
      expect(json.dig("employee", "branch_name")).to eq(employee.branch&.name)
      expect(json["managers"].map { |m| m["name"] }).to include("Morgan Manager")
      expect(json.dig("user", "email")).to eq(user.email)
      expect(json.dig("company", "id")).to eq(company.id)
    end
  end
end
