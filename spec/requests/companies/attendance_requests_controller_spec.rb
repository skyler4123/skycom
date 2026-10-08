# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::AttendanceRequestsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: "owner") }
  let(:employee) { create(:employee, company: company) }
  let(:requester) { create(:employee, company: company) }

  let!(:attendance_request) do
    AttendanceRequest.create!(
      company: company, employee: requester,
      attendance_date: Date.yesterday,
      check_in: Time.zone.parse("#{Date.yesterday} 09:00"),
      check_out: Time.zone.parse("#{Date.yesterday} 17:00"),
      reason: "Field work - no GPS"
    )
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: company.user.email) }

  it "ignores employee_id/status params on create" do
    post company_attendance_requests_path(company), params: {
      attendance_request: {
        attendance_date: Date.yesterday - 1.day,
        check_in: Time.zone.parse("#{Date.yesterday - 1.day} 09:00"),
        reason: "Remote work",
        employee_id: employee.id,
        status: "approved"
      }
    }

    expect(response).to have_http_status(:found)
    created = AttendanceRequest.find_by(company: company, attendance_date: Date.yesterday - 1.day)
    expect(created.employee).to eq(owner)
    expect(created).to be_status_pending
  end

  it "lists requests scoped to the company" do
    get company_attendance_requests_path(company, format: :json)

    expect(response).to have_http_status(:ok)
    ids = JSON.parse(response.body)["attendance_requests"].map { |r| r["id"] }
    expect(ids).to include(attendance_request.id)
  end

  it "approves and creates the day (owner)" do
    expect {
      post approve_company_attendance_request_path(company, attendance_request), as: :json
    }.to change(AttendanceDay, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(attendance_request.reload).to be_status_approved
  end

  it "returns 422 with errors when a day already exists" do
    AttendanceDay.create!(
      company: company, employee: requester, attendance_date: attendance_request.attendance_date,
      attendance_status: :present, total_seconds_worked: 28800
    )

    post approve_company_attendance_request_path(company, attendance_request), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"]).to be_present
    expect(attendance_request.reload).to be_status_pending
  end

  it "returns 403 for an employee without update permission" do
    get sign_in_for_test_path(email: employee.user.email)

    post approve_company_attendance_request_path(company, attendance_request), as: :json

    expect(response).to have_http_status(:forbidden)
  end
end
