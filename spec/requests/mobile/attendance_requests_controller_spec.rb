# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::AttendanceRequestsController", type: :request do
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
      post mobile_attendance_requests_path, params: {
        attendance_request: {
          attendance_date: Date.yesterday,
          check_in: Time.zone.parse("#{Date.yesterday} 09:00"),
          check_out: Time.zone.parse("#{Date.yesterday} 17:00"),
          reason: "Remote work"
        }
      }
    }.to change(AttendanceRequest, :count).by(1)

    created = AttendanceRequest.last
    expect(created.employee.user_id).to eq(user.id)
    expect(created.company).to eq(company)
    expect(created).to be_status_pending
    expect(response).to have_http_status(:found)
  end

  it "redirects with alert when the user has no employee record" do
    stranger = create(:user)
    get sign_in_for_test_path(email: stranger.email)

    post mobile_attendance_requests_path, params: {
      attendance_request: {
        attendance_date: Date.yesterday,
        check_in: Time.zone.parse("#{Date.yesterday} 09:00"),
        reason: "Remote work"
      }
    }

    expect(response).to redirect_to(mobile_home_path)
    expect(flash[:alert]).to be_present
  end
end
