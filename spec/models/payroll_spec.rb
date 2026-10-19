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
end
