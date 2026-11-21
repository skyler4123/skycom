# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::AttendancesController", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { company.employees.find_by(user: user).tap { |record| record.update!(branch: branch) } }

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

  it "stores the submitted GPS coordinates and accuracy" do
    create(:attendance_config, company: company, branch: branch)
    post mobile_company_attendances_path(company), params: {
      attendance: { latitude: 10.773, longitude: 106.694, accuracy: 12 }
    }

    log = AttendanceLog.last
    expect(log.latitude).to be_within(0.000001).of(10.773)
    expect(log.longitude).to be_within(0.000001).of(106.694)
    expect(log.gps_accuracy_meters).to eq(12)
    expect(log.geofence_distance_meters).to eq(0)
    expect(response).to redirect_to(mobile_company_home_path(company))
  end

  it "rejects a check-in outside the branch radius" do
    create(:attendance_config, company: company, branch: branch)
    expect {
      post mobile_company_attendances_path(company), params: {
        attendance: { latitude: 10.8, longitude: 106.8 }
      }
    }.not_to change(AttendanceLog, :count)

    expect(flash[:alert]).to eq("You are outside the allowed check-in area.")
    expect(response).to redirect_to(mobile_company_home_path(company))
  end

  it "rejects a check-in without location when the branch has a config" do
    create(:attendance_config, company: company, branch: branch)
    expect {
      post mobile_company_attendances_path(company)
    }.not_to change(AttendanceLog, :count)

    expect(flash[:alert]).to eq("Location is required to check in.")
  end

  it "ignores a wifi_ssid param" do
    create(:attendance_config, company: company, branch: branch)
    post mobile_company_attendances_path(company), params: {
      attendance: { latitude: 10.773, longitude: 106.694, wifi_ssid: "Clinic_WiFi" }
    }

    expect(AttendanceLog.last.wifi_ssid).to be_nil
  end

  it "accepts a check-in when the branch has no config" do
    expect {
      post mobile_company_attendances_path(company)
    }.to change(AttendanceLog, :count).by(1)
  end
end
