# frozen_string_literal: true

require "rails_helper"

RSpec.describe AttendanceLeave, type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
    it { should belong_to(:decided_by).class_name("Employee").optional }
  end

  describe "enums" do
    it { should define_enum_for(:leave_type).with_values(paid: 0, sick: 1, unpaid: 2) }
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2) }
  end

  describe "validations" do
    it "accepts a valid paid request" do
      request = build(:attendance_leave, company: company, employee: employee)
      expect(request).to be_valid
    end

    it "rejects an end date before the start date" do
      request = build(:attendance_leave, company: company, employee: employee,
        start_date: Date.current, end_date: Date.current - 1.day, days: 1)
      expect(request).not_to be_valid
      expect(request.errors[:end_date]).to be_present
    end

    it "rejects non-positive days" do
      request = build(:attendance_leave, company: company, employee: employee, days: 0)
      expect(request).not_to be_valid
      expect(request.errors[:days]).to be_present
    end

    it "rejects an employee from another company" do
      other_employee = create(:employee, company: create(:company))
      request = build(:attendance_leave, company: company, employee: other_employee)
      expect(request).not_to be_valid
      expect(request.errors[:employee]).to be_present
    end
  end

  describe ".for_year" do
    it "returns only requests that start in the given year" do
      current = create(:attendance_leave, company: company, employee: employee, start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 4, 2))
      create(:attendance_leave, company: company, employee: employee, start_date: Date.new(2025, 4, 1), end_date: Date.new(2025, 4, 2))

      expect(described_class.for_year(2026)).to include(current)
      expect(described_class.for_year(2026).count).to eq(1)
    end
  end
end
