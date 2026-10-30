# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::AttendancesController", type: :request do
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
      post mobile_company_attendances_path(company)
    }.to change(AttendanceLog, :count).by(1)

    log = AttendanceLog.last
    expect(log).to be_log_type_check_in
    expect(log.employee_id).to eq(employee.id)
    expect(response).to redirect_to(mobile_company_home_path(company))
  end

  it "creates a second check-in on the same day" do
    post mobile_company_attendances_path(company)

    expect {
      post mobile_company_attendances_path(company)
    }.to change(AttendanceLog, :count).by(1)

    expect(AttendanceLog.where(employee: employee, log_type: :check_in).count).to eq(2)
    expect(response).to redirect_to(mobile_company_home_path(company))
    expect(flash[:notice]).to eq("Checked in successfully")
  end

  it "returns not found when the user has no employee record" do
    stranger = create(:user)
    get sign_in_for_test_path(email: stranger.email)

    expect {
      post mobile_company_attendances_path(company)
    }.not_to change(AttendanceLog, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not create a check-in for another company" do
    other_company = create(:company)

    expect {
      post mobile_company_attendances_path(other_company)
    }.not_to change(AttendanceLog, :count)

    expect(response).to have_http_status(:not_found)
  end
end
