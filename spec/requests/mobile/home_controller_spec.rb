# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::HomeController", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }

  before { get sign_in_for_test_path(email: user.email) }

  it "uses the company's local day and timezone for check-ins" do
    company.update!(timezone: :plus_7)

    travel_to Time.zone.parse("2026-10-30 01:00") do
      AttendanceLog.create!(
        company: company,
        employee: employee,
        log_type: :check_in,
        logged_at: Time.zone.parse("2026-10-29 17:30")
      )

      get mobile_company_home_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-check-in-status="checked_in"')
      expect(response.body).to include("Today's Check-ins")
      expect(response.body).to include("12:30 AM")
    end
  end
end
