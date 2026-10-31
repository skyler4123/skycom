# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile payroll access", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }
  let!(:payroll) do
    create(
      :payroll,
      company: company,
      employee: employee,
      month: Date.current.beginning_of_month,
      status: :paid,
      net_amount_cents: 486_540
    )
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: user.email) }

  it "redirects to the password gate without an unlock" do
    get mobile_company_payroll_path(company)

    expect(response).to redirect_to(mobile_company_payroll_unlock_path(company))
    follow_redirect!
    expect(response.body).to include("Payroll is private")
    expect(response.body).not_to include("$4,865.40")
  end

  it "renders payroll after a correct password" do
    post mobile_company_payroll_unlock_path(company), params: { password: "Password@1234" }

    expect(response).to redirect_to(mobile_company_payroll_path(company))

    get mobile_company_payroll_path(company)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("$4,865.40")
  end

  it "does not unlock payroll with an incorrect password" do
    post mobile_company_payroll_unlock_path(company), params: { password: "WrongPassword@1234" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Incorrect password")
    expect(response.body).not_to include("$4,865.40")

    get mobile_company_payroll_path(company)

    expect(response).to redirect_to(mobile_company_payroll_unlock_path(company))
  end

  it "revokes an existing unlock when the gate receives an incorrect password" do
    post mobile_company_payroll_unlock_path(company), params: { password: "Password@1234" }
    post mobile_company_payroll_unlock_path(company), params: { password: "WrongPassword@1234" }

    get mobile_company_payroll_path(company)

    expect(response).to redirect_to(mobile_company_payroll_unlock_path(company))
  end

  it "requires the password again after five minutes" do
    post mobile_company_payroll_unlock_path(company), params: { password: "Password@1234" }
    expect(response).to redirect_to(mobile_company_payroll_path(company))

    travel_to(5.minutes.from_now + 1.second) do
      get mobile_company_payroll_path(company)

      expect(response).to redirect_to(mobile_company_payroll_unlock_path(company))
    end
  end
end
