require 'rails_helper'

RSpec.describe AttendanceRequest, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
    it { should belong_to(:decided_by).class_name("Employee").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:attendance_date) }
    it { should validate_presence_of(:check_in) }
    it { should validate_presence_of(:reason) }
  end

  describe "guards" do
    it "factory creates a valid record out of the box" do
      expect(create(:attendance_request)).to be_persisted
    end

    let(:company) { create(:company) }
    let(:employee) { create(:employee, company: company) }

    it "rejects future attendance_date" do
      req = build(:attendance_request, company: company, employee: employee, attendance_date: Date.tomorrow)
      expect(req).not_to be_valid
      expect(req.errors[:attendance_date]).to be_present
    end

    it "rejects check_out at or before check_in" do
      check_in = Time.zone.parse("2026-10-07 09:00")
      req = build(:attendance_request, company: company, employee: employee,
        attendance_date: Date.yesterday, check_in: check_in, check_out: check_in)
      expect(req).not_to be_valid
      expect(req.errors[:check_out]).to be_present
    end

    it "rejects a second live request for the same employee and date" do
      create(:attendance_request, company: company, employee: employee, attendance_date: Date.yesterday)
      dup = build(:attendance_request, company: company, employee: employee, attendance_date: Date.yesterday)
      expect(dup).not_to be_valid
    end

    it "rejects a branch from another company" do
      other_branch = create(:branch, company: create(:company))
      req = build(:attendance_request, company: company, employee: employee, branch: other_branch)
      expect(req).not_to be_valid
      expect(req.errors[:branch]).to be_present
    end

    it "allows decided_by to be blank on pending" do
      req = build(:attendance_request, company: company, employee: employee, decided_by: nil)
      expect(req.errors[:decided_by]).to be_empty
    end
  end
end
