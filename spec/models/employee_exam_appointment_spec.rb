# spec/models/employee_exam_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeExamAppointment, type: :model do
  let(:exam) { create(:exam) }
  let(:employee) { create(:employee, company: exam.company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:exam) }
    it { should have_many(:employee_question_appointments).dependent(:destroy) }
  end

  describe "validations" do
    it "requires a positive attempt number" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 0)
      expect(appointment).not_to be_valid
      expect(appointment.errors[:attempt_number]).to be_present
    end

    it "requires a unique attempt number per employee and exam" do
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :graded)
      duplicate = build(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:attempt_number]).to be_present
    end

    it "prevents two active attempts for the same employee and exam" do
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :assigned)
      duplicate = build(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 2, workflow_status: :in_progress)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include("An active attempt already exists")
    end

    it "allows a new attempt when the previous one is completed" do
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :graded)
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 2)).to be_valid
    end
  end

  describe "status predicates" do
    it "reports active, completed, and pending review" do
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)).to be_active
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :in_progress)).to be_active
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :graded)).to be_completed
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :expired)).to be_completed
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :submitted)).to be_pending_review
    end
  end

  describe "#can_retake?" do
    it "is false for an active attempt" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)
      expect(appointment.can_retake?).to be(false)
    end

    it "is false for a submitted attempt" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :submitted)
      expect(appointment.can_retake?).to be(false)
    end

    it "is false when a single-attempt exam is completed" do
      appointment = create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :graded)
      exam.update!(max_attempts: 1)
      expect(appointment.can_retake?).to be(false)
    end

    it "is true when attempts remain" do
      appointment = create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :graded)
      exam.update!(max_attempts: 2)
      expect(appointment.can_retake?).to be(true)
    end

    it "is true when attempts are unlimited" do
      appointment = create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :graded)
      exam.update!(max_attempts: nil)
      expect(appointment.can_retake?).to be(true)
    end
  end

  describe "#time_remaining_seconds" do
    it "is nil without a deadline" do
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, deadline_at: nil).time_remaining_seconds).to be_nil
    end

    it "clamps at zero for a past deadline" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, deadline_at: 1.minute.ago)
      expect(appointment.time_remaining_seconds).to eq(0)
    end

    it "returns positive seconds for a future deadline" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, deadline_at: 10.minutes.from_now)
      expect(appointment.time_remaining_seconds).to be_between(1, 600)
    end
  end

  describe "#expired_by_time?" do
    it "is true for an in-progress attempt past its deadline" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :in_progress, deadline_at: 1.minute.ago)
      expect(appointment).to be_expired_by_time
    end

    it "is false for an in-progress attempt before its deadline" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :in_progress, deadline_at: 1.minute.from_now)
      expect(appointment).not_to be_expired_by_time
    end

    it "is false for an assigned attempt" do
      appointment = build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned, deadline_at: 1.minute.ago)
      expect(appointment).not_to be_expired_by_time
    end
  end

  describe "#gradeable?" do
    it "is true only for submitted attempts" do
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :submitted)).to be_gradeable
      expect(build(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :in_progress)).not_to be_gradeable
    end
  end
end
