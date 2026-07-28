require "rails_helper"

RSpec.feature "Mobile Check In", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { create(:employee, user: user, company: company, branch: branch) }

  scenario "creates attendance log and shows success notice" do
    sign_in(user)
    visit mobile_home_path

    click_button "Check In"

    expect(page).to have_content("Checked in successfully")
    expect(AttendanceLog.count).to eq(1)
  end

  scenario "records check_in log type with correct employee" do
    sign_in(user)
    visit mobile_home_path

    click_button "Check In"

    expect(page).to have_content("Checked in successfully")

    log = AttendanceLog.last
    expect(log.log_type).to eq("check_in")
    expect(log.employee_id).to be_present
    expect(log.company_id).to eq(company.id)
  end
end
