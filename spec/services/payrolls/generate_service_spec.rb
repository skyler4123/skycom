# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payrolls::GenerateService do
  let(:company) { create(:company) }
  let(:employee) do
    create(
      :employee,
      company: company,
      monthly_salary_cents: 2_100_000,
      monthly_allowance_cents: 210_000,
      currency: :usd
    )
  end
  let(:month) { Date.parse("2026-08-01") }
  let!(:attendance_month) do
    AttendanceMonth.create!(
      company: company,
      employee: employee,
      month: month,
      total_work_minutes: 10_080,
      total_present_days: 21,
      total_absent_days: 0,
      total_records: 21,
      total_overtime_minutes: 60
    )
  end

  describe "#call" do
    it "calculates base, allowance, overtime, tax, deductions, and net" do
      described_class.new(company: company, month: month).call

      payroll = Payroll.find_by!(company: company, employee: employee, month: month)

      expect(payroll.base_amount_cents).to eq(2_100_000)
      expect(payroll.allowance_amount_cents).to eq(210_000)
      expect(payroll.overtime_amount_cents).to eq(18_173)
      expect(payroll.gross_amount_cents).to eq(2_328_173)
      expect(payroll.tax_amount_cents).to eq(232_817)
      expect(payroll.deduction_amount_cents).to eq(195_567)
      expect(payroll.net_amount_cents).to eq(1_899_789)
      expect(payroll.currency).to eq("usd")
      expect(payroll.status).to eq("draft")
    end

    it "keeps the attendance totals in metadata" do
      described_class.new(company: company, month: month).call

      payroll = Payroll.find_by!(company: company, employee: employee, month: month)

      expect(payroll.metadata["total_present_days"]).to eq(21)
      expect(payroll.metadata["total_overtime_minutes"]).to eq(60)
    end

    it "recalculates an existing payroll instead of creating a duplicate" do
      described_class.new(company: company, month: month).call
      employee.update!(monthly_salary_cents: 4_200_000)

      expect do
        described_class.new(company: company, month: month).call
      end.not_to change(Payroll, :count)

      payroll = Payroll.find_by!(company: company, employee: employee, month: month)
      expect(payroll.base_amount_cents).to eq(4_200_000)
      expect(payroll.net_amount_cents).to eq(3_628_218)
    end

    it "produces zero money when the employee has no salary" do
      employee.update!(monthly_salary_cents: 0, monthly_allowance_cents: 0)

      described_class.new(company: company, month: month).call

      payroll = Payroll.find_by!(company: company, employee: employee, month: month)
      expect(payroll.gross_amount_cents).to eq(0)
      expect(payroll.net_amount_cents).to eq(0)
    end
  end
end
