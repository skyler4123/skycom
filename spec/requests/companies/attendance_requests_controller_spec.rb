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

  it "ignores bogus filter params instead of 500ing" do
    get company_attendance_requests_path(company, format: :json),
      params: { status: "hijack", from: "not-a-date", to: "%%%" }

    expect(response).to have_http_status(:ok)
    ids = JSON.parse(response.body)["attendance_requests"].map { |r| r["id"] }
    expect(ids).to include(attendance_request.id)
  end

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

  describe "GET #index filters" do
    let!(:alice_employee) { create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") } }
    let!(:bob_employee) { create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") } }
    let!(:alice_request) do
      AttendanceRequest.create!(
        company: company, employee: alice_employee,
        attendance_date: Date.parse("2026-09-10"),
        check_in: Time.zone.parse("2026-09-10 09:00"),
        check_out: Time.zone.parse("2026-09-10 17:00"),
        reason: "Alice field work", business_type: :field_work
      )
    end
    let!(:bob_request) do
      AttendanceRequest.create!(
        company: company, employee: bob_employee,
        attendance_date: Date.parse("2026-09-12"),
        check_in: Time.zone.parse("2026-09-12 09:00"),
        reason: "Bob remote work", business_type: :remote_work
      )
    end

    def request_ids(body)
      JSON.parse(body)["attendance_requests"].map { |r| r["id"] }
    end

    it "filters by employee_name (partial, case-insensitive)" do
      get company_attendance_requests_path(company, format: :json), params: { employee_name: "alice" }
      ids = request_ids(response.body)
      expect(ids).to include(alice_request.id)
      expect(ids).not_to include(bob_request.id)
    end

    it "filters by business_type" do
      get company_attendance_requests_path(company, format: :json), params: { business_type: "remote_work" }
      ids = request_ids(response.body)
      expect(ids).to include(bob_request.id)
      expect(ids).not_to include(alice_request.id)
    end

    it "filters by from/to range on attendance_date" do
      get company_attendance_requests_path(company, format: :json), params: { from: "2026-09-11", to: "2026-09-13" }
      ids = request_ids(response.body)
      expect(ids).to include(bob_request.id)
      expect(ids).not_to include(alice_request.id)
    end

    it "ignores bogus business_type instead of 500ing" do
      get company_attendance_requests_path(company, format: :json), params: { business_type: "hijack" }
      expect(response).to have_http_status(:ok)
      expect(request_ids(response.body)).to include(alice_request.id, bob_request.id)
    end
  end
end
