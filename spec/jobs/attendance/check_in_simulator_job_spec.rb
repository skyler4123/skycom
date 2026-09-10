# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attendance::CheckInSimulatorJob do
  def stub_development
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
  end

  it "does nothing outside development" do
    company = create(:company)
    branch = create(:branch, company: company)
    employee = create(:employee, company: company, branch: branch)
    create(:scheduled_shift, company: company, branch: branch, employee: employee)
    create(:attendance_policy, company: company, branch: branch)

    expect {
      described_class.perform_now
    }.not_to change(AttendanceLog, :count)
  end

  context "in development" do
    before { stub_development }

    it "creates one check_in log when every employee has a scheduled shift today" do
      company = create(:company)
      branch = create(:branch, company: company)
      create(:employee, company: company, branch: branch)
      create(:attendance_policy, company: company, branch: branch)
      # The random pick may hit any employee (incl. the auto-created owner),
      # so give every employee a scheduled shift to keep the pick deterministic.
      company.employees.kept.each do |emp|
        create(:scheduled_shift, company: company, branch: branch, employee: emp)
      end

      expect {
        described_class.perform_now
      }.to change(AttendanceLog, :count).by(1)
    end

    it "ensures today's shift and checks in when no shift exists" do
      company = create(:company)
      branch = create(:branch, company: company)
      create(:employee, company: company, branch: branch)
      create(:attendance_policy, company: company, branch: branch)
      expect(company.employees.kept.count).to be >= 1

      expect {
        described_class.perform_now
      }.to change(AttendanceLog, :count).by(1)

      log = AttendanceLog.order(created_at: :desc).first
      expect(log.log_type).to eq("check_in")
      expect(log.logged_at.to_date).to eq(Date.current)
      shift = ScheduledShift.find_by(employee: log.employee, work_date: Date.current)
      expect(shift).to be_status_active
    end

    it "does not duplicate or touch an already-checked-in shift" do
      company = create(:company)
      branch = create(:branch, company: company)
      employee = create(:employee, company: company, branch: branch)
      create(:attendance_policy, company: company, branch: branch)
      company.employees.kept.each do |emp|
        create(:scheduled_shift, company: company, branch: branch, employee: emp)
      end

      described_class.perform_now
      # Whoever was picked is now :active; a second run picks at random again —
      # assert no duplicate shift rows are ever created for (employee, today).
      described_class.perform_now

      company.employees.kept.each do |emp|
        expect(ScheduledShift.where(employee: emp, work_date: Date.current).count).to eq(1)
      end
      expect(employee.scheduled_shifts.where(work_date: Date.current).count).to eq(1)
    end

    it "skips when the picked employee has no branch and the company has none" do
      company = create(:company)
      # Company init creates only an owner employee (branch-less) and no branches.
      expect(company.branches).to be_empty

      expect {
        described_class.perform_now
      }.not_to change(AttendanceLog, :count)
    end
  end
end
