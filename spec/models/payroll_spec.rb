require "rails_helper"

RSpec.describe Payroll, type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }

  it "validates presence" do
    payroll = Payroll.new(company: company, employee: employee, month: Date.current.beginning_of_month)
    expect(payroll).to be_valid
  end

  it "enforces uniqueness per company/employee/month" do
    create(:payroll, company: company, employee: employee, month: Date.current.beginning_of_month)
    dup = build(:payroll, company: company, employee: employee, month: Date.current.beginning_of_month)
    expect(dup).not_to be_valid
  end

  it "defaults to USD and zero money" do
    payroll = Payroll.new(company: company, employee: employee, month: Date.current.beginning_of_month)

    expect(payroll.currency).to eq("usd")
    expect(payroll.net_amount_cents).to eq(0)
  end

  it "combines tax and social deductions" do
    payroll = build(:payroll, company: company, employee: employee,
      tax_amount_cents: 10_000, deduction_amount_cents: 8_400)

    expect(payroll.total_deductions_cents).to eq(18_400)
  end

  it "rejects negative money" do
    payroll = build(:payroll, company: company, employee: employee, net_amount_cents: -1)

    expect(payroll).not_to be_valid
    expect(payroll.errors[:net_amount_cents]).to be_present
  end
end
