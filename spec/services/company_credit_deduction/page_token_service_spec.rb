# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyCreditDeduction::PageTokenService do
  let(:company) { create(:company) }
  let(:employee) { company.employees.find_by!(user: company.user) }
  let(:page) { "companies/dashboards#index" }

  def generate_token
    described_class.generate(page: page, company: company, employee: employee)
  end

  it "generates a token carrying the page, company, and employee" do
    payload = described_class.verify(generate_token)

    expect(payload).to include(
      "page" => page,
      "company_id" => company.id,
      "employee_id" => employee.id
    )
    expect(payload["nonce"]).to be_present
  end

  it "rejects a tampered token" do
    token = generate_token

    expect(described_class.verify("#{token}tampered")).to be_nil
  end

  it "rejects a blank token" do
    expect(described_class.verify(nil)).to be_nil
    expect(described_class.verify("")).to be_nil
  end

  it "rejects an expired token" do
    token = nil

    travel_to(2.hours.ago) { token = generate_token }

    expect(described_class.verify(token)).to be_nil
  end
end
