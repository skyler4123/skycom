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

    it "skips fail-safe when no employee has a scheduled shift today" do
      company = create(:company)
      branch = create(:branch, company: company)
      create(:employee, company: company, branch: branch)
      create(:attendance_policy, company: company, branch: branch)

      expect {
        described_class.perform_now
      }.not_to change(AttendanceLog, :count)
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
