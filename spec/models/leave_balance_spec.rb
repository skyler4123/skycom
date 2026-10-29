# frozen_string_literal: true

require "rails_helper"

RSpec.describe LeaveBalance, type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:year) { Date.current.year }

  describe "validations" do
    it "allows one balance per employee and year" do
      create(:leave_balance, company: company, employee: employee, year: year)
      duplicate = build(:leave_balance, company: company, employee: employee, year: year)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:employee_id]).to be_present
    end

    it "rejects a negative entitlement" do
      expect(build(:leave_balance, company: company, employee: employee, entitled_days: -1)).not_to be_valid
    end
  end

  describe "#approved_days, #pending_days, #remaining_days" do
    let!(:balance) { create(:leave_balance, company: company, employee: employee, year: year, entitled_days: 14) }

    before do
      create(:leave_request, company: company, employee: employee, status: :approved, leave_type: :paid,
        start_date: Date.new(year, 1, 5), end_date: Date.new(year, 1, 6), days: 2)
      create(:leave_request, company: company, employee: employee, status: :pending, leave_type: :paid,
        start_date: Date.new(year, 2, 2), end_date: Date.new(year, 2, 2), days: 1)
      create(:leave_request, company: company, employee: employee, status: :approved, leave_type: :sick,
        start_date: Date.new(year, 3, 2), end_date: Date.new(year, 3, 3), days: 2)
    end

    it "derives used paid days from approved requests" do
      expect(balance.approved_days).to eq(2.0)
    end

    it "derives pending paid days from pending requests" do
      expect(balance.pending_days).to eq(1.0)
    end

    it "subtracts approved paid days from the entitlement" do
      expect(balance.remaining_days).to eq(12.0)
    end

    it "ignores requests from other years" do
      create(:leave_request, company: company, employee: employee, status: :approved, leave_type: :paid,
        start_date: Date.new(year - 1, 12, 30), end_date: Date.new(year - 1, 12, 31), days: 2)

      expect(balance.approved_days).to eq(2.0)
    end
  end

  describe ".for" do
    it "returns a zero balance when the employee has no record" do
      balance = LeaveBalance.for(employee: employee, year: year)

      expect(balance).to be_a(LeaveBalance)
      expect(balance).not_to be_persisted
      expect(balance.entitled_days).to eq(0)
      expect(balance.remaining_days).to eq(0)
    end
  end
end
