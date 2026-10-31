# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Attendance Request", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:manager) { create(:employee, company: company, name: "Alex Approver") }
  let!(:employee) { company.employees.find_by(user: user) }
  let!(:employee_group) { create(:employee_group, company: company, manager: manager, name: "Support Team") }
  let!(:appointment) do
    create(:employee_employee_group_appointment, company: company, employee: employee, employee_group: employee_group)
  end

  # Native date/time inputs are unreliable through send_keys in headless
  # Chrome; set them through the DOM the way the picker would.
  def set_native_field(name, value)
    page.execute_script(
      "const el = document.querySelector(arguments[0]); el.value = arguments[1]; el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true }));",
      "[name='attendance_request[#{name}]']",
      value
    )
  end

  scenario "submits a valid attendance request" do
    sign_in(user)
    visit new_mobile_company_attendance_request_path(company)

    expect(page).to have_content("New Request")
    set_native_field("attendance_date", Date.yesterday.strftime("%Y-%m-%d"))
    select "Remote Work", from: "Type"
    set_native_field("check_in_time", "09:00")
    set_native_field("check_out_time", "17:00")
    fill_in "Reason", with: "Client visit"
    expect(page).to have_content("12/240")
    click_button "Submit Request"

    expect(page).to have_content("Attendance request submitted successfully")
    expect(AttendanceRequest.count).to eq(1)
    expect(AttendanceRequest.last.employee).to eq(employee)
    expect(AttendanceRequest.last).to be_status_pending
    expect(AttendanceRequest.last.business_type).to eq("remote_work")
  end

  scenario "shows the employee's group managers" do
    sign_in(user)
    visit new_mobile_company_attendance_request_path(company)

    expect(page).to have_content("Your Managers")
    expect(page).to have_content("Alex Approver")
    expect(page).to have_content("AA")
    expect(page).not_to have_content("Sample")
  end

  scenario "shows every group manager" do
    second_manager = create(:employee, company: company, name: "Blair Approver")
    second_group = create(:employee_group, company: company, manager: second_manager, name: "Field Team")
    create(
      :employee_employee_group_appointment,
      company: company,
      employee: employee,
      employee_group: second_group
    )

    sign_in(user)
    visit new_mobile_company_attendance_request_path(company)

    expect(page).to have_content("Alex Approver")
    expect(page).to have_content("Blair Approver")
  end

  scenario "shows validation errors and does not create a request" do
    sign_in(user)
    visit new_mobile_company_attendance_request_path(company)

    set_native_field("attendance_date", Date.yesterday.strftime("%Y-%m-%d"))
    select "Onsite Miss", from: "Type"
    set_native_field("check_in_time", "09:00")
    click_button "Submit Request"

    expect(page).to have_content("can't be blank")
    expect(AttendanceRequest.count).to eq(0)
  end

  scenario "rejects a future attendance date" do
    sign_in(user)
    visit new_mobile_company_attendance_request_path(company)

    set_native_field("attendance_date", Date.tomorrow.strftime("%Y-%m-%d"))
    select "Field Work", from: "Type"
    set_native_field("check_in_time", "09:00")
    fill_in "Reason", with: "Site inspection"
    click_button "Submit Request"

    expect(page).to have_content("cannot be in the future")
    expect(AttendanceRequest.count).to eq(0)
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit new_mobile_company_attendance_request_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "redirects an unauthorized employee away from the new request form" do
    unauthorized_user = create(:user)
    create(:employee, user: unauthorized_user, company: company)

    sign_in(unauthorized_user)
    visit new_mobile_company_attendance_request_path(company)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end
end
