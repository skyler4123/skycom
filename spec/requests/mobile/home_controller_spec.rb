# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::HomeController", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }

  before { get sign_in_for_test_path(email: user.email) }

  it "renders only the shell" do
    get mobile_company_home_path(company)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="mobile--companies--home--index"')
    expect(response.body).to include(
      %(data-json-url="#{mobile_company_home_path(company, format: :json)}")
    )
    expect(response.body).not_to include("Paid Leave")
  end

  it "returns the company-local check-in state as JSON" do
    company.update!(timezone: :plus_7)

    travel_to Time.zone.parse("2026-10-30 01:00") do
      AttendanceLog.create!(
        company: company,
        employee: employee,
        log_type: :check_in,
        logged_at: Time.zone.parse("2026-10-29 17:30")
      )

      get mobile_company_home_path(company, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("company", "utc_offset")).to eq(7 * 3600)
      expect(json["checked_in"]).to be(true)
      expect(json["check_in_logs"].size).to eq(1)
      expect(json["check_in_logs"].first["logged_at"]).to be_present
      expect(json["today_logs"].first["branch_name"]).to be_present
    end
  end
end
