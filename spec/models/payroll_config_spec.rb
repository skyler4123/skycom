require "rails_helper"

RSpec.describe PayrollConfig, type: :model do
  let(:company) { create(:company) }

  it "creates with defaults" do
    config = PayrollConfig.for_company!(company)
    expect(config.date_basis).to eq("month")
    expect(config.include_attendance_months).to be true
    expect(config.include_attendance_days).to be false
    expect(config.branch_ids).to eq([])
    expect(config.employee_ids).to eq([])
  end

  it "enforces one config per company" do
    PayrollConfig.for_company!(company)
    expect { PayrollConfig.create!(company: company) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "for_company! returns existing" do
    c1 = PayrollConfig.for_company!(company)
    c2 = PayrollConfig.for_company!(company)
    expect(c1.id).to eq(c2.id)
  end
end
