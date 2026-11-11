# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::AttendanceRequestsController", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { create(:employee, user: user, company: company, branch: branch) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: user.email) }

  it "creates a pending request for own employee" do
    expect {
      post mobile_company_attendance_requests_path(company), params: {
        attendance_request: {
          attendance_date: Date.yesterday,
          check_in_time: "09:00",
          check_out_time: "17:00",
          reason: "Remote work"
        }
      }
    }.to change(AttendanceRequest, :count).by(1)

    created = AttendanceRequest.last
    expect(created.employee.user_id).to eq(user.id)
    expect(created.company).to eq(company)
    expect(created).to be_status_pending
    expect(response).to redirect_to(new_mobile_company_attendance_request_path(company))
  end

  it "redirects with alert when the employee lacks create permission" do
    other_user = create(:user)
    create(:employee, user: other_user, company: company)
    get sign_in_for_test_path(email: other_user.email)

    expect {
      post mobile_company_attendance_requests_path(company), params: {
        attendance_request: {
          attendance_date: Date.yesterday,
          check_in_time: "09:00",
          reason: "Remote work"
        }
      }
    }.not_to change(AttendanceRequest, :count)

    expect(response).to redirect_to(mobile_company_home_path(company))
    expect(flash[:alert]).to be_present
  end

  it "returns not found when the user has no employee record" do
    stranger = create(:user)
    get sign_in_for_test_path(email: stranger.email)

    expect {
      post mobile_company_attendance_requests_path(company), params: {
        attendance_request: {
          attendance_date: Date.yesterday,
          check_in_time: "09:00",
          reason: "Remote work"
        }
      }
    }.not_to change(AttendanceRequest, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not create a request for another company" do
    other_company = create(:company)

    expect {
      post mobile_company_attendance_requests_path(other_company), params: {
        attendance_request: {
          attendance_date: Date.yesterday,
          check_in_time: "09:00",
          reason: "Cross-tenant attempt"
        }
      }
    }.not_to change(AttendanceRequest, :count)

    expect(response).to have_http_status(:not_found)
  end


  it "renders only the shell on the new page" do
    get new_mobile_company_attendance_request_path(company)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="mobile--companies--attendance-requests--new"')
    expect(response.body).to include(
      %(data-json-url="#{new_mobile_company_attendance_request_path(company, format: :json)}")
    )
    expect(response.body).not_to include("Your Managers")
  end

  it "returns the form payload as JSON" do
    get new_mobile_company_attendance_request_path(company, format: :json)

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json.dig("employee", "name")).to eq(user.employees.find_by(company_id: company.id).name)
    expect(json.dig("company", "id")).to eq(company.id)
    expect(json["business_types"]).to eq(AttendanceRequest.business_types.keys)
    expect(json.dig("defaults", "business_type")).to eq("onsite_miss")
    expect(json["managers"]).to be_an(Array)
  end

  it "re-renders the shell with errors and values when the request is invalid" do
    expect {
      post mobile_company_attendance_requests_path(company), params: {
        attendance_request: {
          attendance_date: Date.yesterday,
          business_type: "remote_work",
          check_in_time: "09:00"
        }
      }
    }.not_to change(AttendanceRequest, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('data-controller="mobile--companies--attendance-requests--new"')
    expect(response.body).to include("data-errors")
    expect(response.body).to include("Reason")
    expect(response.body).to include("data-values")
    expect(response.body).to include("remote_work")
  end
end
