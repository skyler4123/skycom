# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::PayrollService do
  let(:company) { create(:company) }
  let(:branch) do
    create(:branch, company: company).tap { |record| record.update_columns(discarded_at: nil) }
  end
  let!(:owner) do
    company.employees.find_by!(business_type: :owner).tap { |employee| employee.update!(branch: branch) }
  end
  let(:current_month) { Date.current.beginning_of_month }

  before do
    owner.update!(monthly_salary_cents: 2_100_000, monthly_allowance_cents: 210_000)
  end

  describe ".ensure_current_month!" do
    it "creates a current-month attendance rollup and payroll draft for the owner" do
      described_class.ensure_current_month!(company: company)

      attendance = owner.attendance_months.find_by!(month: current_month..current_month.end_of_month)
      payroll = owner.payrolls.find_by!(month: current_month..current_month.end_of_month)

      expect(attendance.total_present_days).to be >= 1
      expect(payroll).to be_status_draft
      expect(payroll.attendance_month).to eq(attendance)
      expect(payroll.net_amount_cents).to be > 0
    end

    it "keeps existing current-month attendance totals" do
      attendance = AttendanceMonth.create!(
        company: company,
        branch: branch,
        employee: owner,
        month: current_month,
        total_work_minutes: 1_440,
        total_present_days: 3,
        total_records: 3
      )

      described_class.ensure_current_month!(company: company)

      payroll = owner.payrolls.find_by!(month: current_month..current_month.end_of_month)

      expect(attendance.reload.total_present_days).to eq(3)
      expect(payroll.metadata["total_present_days"]).to eq(3)
    end

    it "backfills a zero current-month rollup left by an unresolved attendance day" do
      AttendanceMonth.create!(
        company: company,
        branch: branch,
        employee: owner,
        month: current_month,
        total_work_minutes: 0,
        total_present_days: 0,
        total_absent_days: 1,
        total_records: 1
      )

      described_class.ensure_current_month!(company: company)

      attendance = owner.attendance_months.find_by!(month: current_month..current_month.end_of_month)
      payroll = owner.payrolls.find_by!(month: current_month..current_month.end_of_month)

      expect(attendance.total_present_days).to be >= 1
      expect(payroll.net_amount_cents).to be > 0
    end

    it "does not duplicate the attendance rollup or payroll when run twice" do
      described_class.ensure_current_month!(company: company)

      expect do
        described_class.ensure_current_month!(company: company)
      end.not_to change {
        [
          AttendanceMonth.where(employee: owner, month: current_month..current_month.end_of_month).count,
          Payroll.where(employee: owner, month: current_month..current_month.end_of_month).count
        ]
      }
    end
  end
end
