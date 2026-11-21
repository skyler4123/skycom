# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Check In", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { company.employees.find_by(user: user).tap { |record| record.update!(branch: branch) } }

  before { grant_mobile_geolocation }

  def geofence!
    create(
      :attendance_config,
      company: company,
      branch: branch,
      latitude: 10.773,
      longitude: 106.694,
      allowed_radius_meters: 100
    )
  end

  scenario "creates attendance log and shows success notice" do
    geofence!
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(AttendanceLog.count).to eq(1)
  end

  scenario "records check_in log type with correct employee" do
    geofence!
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")

    log = AttendanceLog.last
    expect(log.log_type).to eq("check_in")
    expect(log.employee_id).to eq(employee.id)
    expect(log.company_id).to eq(company.id)
  end

  scenario "allows multiple check-ins and shows every time" do
    geofence!
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(page).to have_button("Check In Again")

    click_button "Check In Again"

    expect(page).to have_content("Checked in successfully")
    expect(page).to have_button("Check In Again")
    expect(page).to have_content(/today's check-ins/i)
    expect(page).to have_css("[data-check-in-time]", count: 2)
    expect(AttendanceLog.where(employee: employee, log_type: :check_in).count).to eq(2)
  end

  scenario "stores the device coordinates on the attendance log" do
    geofence!
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    log = AttendanceLog.last
    expect(log.latitude).to be_within(0.000001).of(10.773)
    expect(log.longitude).to be_within(0.000001).of(106.694)
    expect(log.gps_accuracy_meters).to eq(10)
    expect(log.geofence_distance_meters).to eq(0)
  end

  scenario "rejects a check-in outside the branch radius" do
    geofence!
    grant_mobile_geolocation(latitude: 10.8, longitude: 106.8)
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("You are outside the allowed check-in area.")
    expect(AttendanceLog.count).to eq(0)
  end

  scenario "does not submit when location permission is denied" do
    geofence!
    deny_mobile_geolocation
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Location permission is required to check in.")
    expect(AttendanceLog.count).to eq(0)
  end

  scenario "checks in when the branch has no geofence config" do
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(AttendanceLog.last.latitude).to be_present
  end

  scenario "checks in without location when the branch has no config and permission is denied" do
    deny_mobile_geolocation
    sign_in(user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(AttendanceLog.last.latitude).to be_nil
  end

  scenario "uses the company's local day and timezone for check-ins" do
    company.update!(timezone: :plus_7)
    sign_in(user)

    company_midnight = Time.current.getlocal(7 * 3600).beginning_of_day
    AttendanceLog.create!(
      company: company,
      employee: employee,
      log_type: :check_in,
      logged_at: company_midnight
    )

    visit mobile_company_home_path(company)

    expect(page).to have_css("[data-check-in-status='checked_in']")
    expect(page).to have_content(/today's check-ins/i)
    expect(page).to have_content("12:00 AM")
  end

  scenario "lets any company member check themselves in" do
    member_user = create(:user)
    member = create(:employee, user: member_user, company: company, name: "Member Check In")

    sign_in(member_user)
    visit mobile_company_home_path(company)

    click_button "Clock In"

    expect(page).to have_content("Checked in successfully")
    expect(AttendanceLog.last.employee).to eq(member)
    expect(AttendanceLog.last.company).to eq(company)
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_home_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
