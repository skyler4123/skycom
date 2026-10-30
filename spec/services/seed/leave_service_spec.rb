# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::LeaveService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let!(:owner) { company.employees.find_by(business_type: :owner) }
  let!(:staff) { create(:employee, company: company, branch: branch) }

  it "creates a paid-leave balance for every employee" do
    described_class.create_samples!(company: company)

    expect(AttendanceBalance.where(company: company, year: Date.current.year).count).to eq(company.employees.count)
    expect(AttendanceBalance.find_by!(employee: staff, year: Date.current.year).entitled_days).to eq(14)
  end

  it "creates approved and pending paid leave requests" do
    described_class.create_samples!(company: company)

    balance = AttendanceBalance.find_by!(employee: owner, year: Date.current.year)

    expect(balance.approved_days).to be > 0
    expect(balance.pending_days).to be > 0
  end

  it "is idempotent when run twice" do
    described_class.create_samples!(company: company)

    expect do
      described_class.create_samples!(company: company)
    end.not_to change(AttendanceLeave, :count)
  end
end
