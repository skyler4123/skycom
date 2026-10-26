# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::AttendancesController", type: :request do
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

  it "creates a check-in log for the employee" do
    expect {
      post mobile_attendances_path
    }.to change(AttendanceLog, :count).by(1)

    log = AttendanceLog.last
    expect(log).to be_log_type_check_in
    expect(log.employee_id).to eq(employee.id)
    expect(response).to redirect_to(mobile_home_path)
  end

  it "does not create a second check-in on the same day" do
    post mobile_attendances_path

    expect {
      post mobile_attendances_path
    }.not_to change(AttendanceLog, :count)

    expect(response).to redirect_to(mobile_home_path)
    expect(flash[:alert]).to eq("Already checked in today")
  end

  it "redirects with an alert when the user has no employee record" do
    stranger = create(:user)
    get sign_in_for_test_path(email: stranger.email)

    expect {
      post mobile_attendances_path
    }.not_to change(AttendanceLog, :count)

    expect(response).to redirect_to(mobile_home_path)
    expect(flash[:alert]).to be_present
  end
end
