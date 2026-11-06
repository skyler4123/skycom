# spec/services/exams/assign_service_spec.rb
require "rails_helper"

RSpec.describe Exams::AssignService, :active_job do
  let(:company) { create(:company) }
  let(:exam) { create(:exam, company: company) }
  let(:assigner) { create(:employee, company: company) }

  describe ".call" do
    it "assigns selected employees to a published exam" do
      exam.publish!
      employees = create_list(:employee, 2, company: company)

      result = described_class.call(exam: exam, employee_ids: employees.map(&:id), assigned_by: assigner)

      expect(result[:success]).to be(true)
      expect(result[:assigned_count]).to eq(2)
      expect(result[:skipped_count]).to eq(0)
      appointments = exam.employee_exam_appointments.where(employee: employees)
      expect(appointments.count).to eq(2)
      expect(appointments.map(&:workflow_status)).to all(eq("assigned"))
      expect(appointments.map(&:attempt_number)).to all(eq(1))
      expect(appointments.map(&:assigned_by_employee_id)).to all(eq(assigner.id))
    end

    it "skips employees who already have an appointment" do
      exam.publish!
      existing, fresh = create_list(:employee, 2, company: company)
      create(:employee_exam_appointment, exam: exam, employee: existing, workflow_status: :assigned)

      result = described_class.call(exam: exam, employee_ids: [ existing.id, fresh.id ], assigned_by: assigner)

      expect(result[:success]).to be(true)
      expect(result[:assigned_count]).to eq(1)
      expect(result[:skipped_count]).to eq(1)
      expect(exam.employee_exam_appointments.where(employee: existing).count).to eq(1)
      expect(exam.employee_exam_appointments.where(employee: fresh).count).to eq(1)
    end

    it "ignores employees from another company" do
      exam.publish!
      valid_employee = create(:employee, company: company)
      other_employee = create(:employee)

      result = described_class.call(exam: exam, employee_ids: [ valid_employee.id, other_employee.id ], assigned_by: assigner)

      expect(result[:success]).to be(true)
      expect(result[:assigned_count]).to eq(1)
      expect(exam.employee_exam_appointments.where(employee: other_employee)).to be_empty
    end

    it "fails for a draft exam" do
      result = described_class.call(exam: exam, employee_ids: [ create(:employee, company: company).id ], assigned_by: assigner)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Publish the exam before assigning employees.")
    end

    it "fails for an archived exam" do
      exam.publish!
      exam.archive!

      result = described_class.call(exam: exam, employee_ids: [ create(:employee, company: company).id ], assigned_by: assigner)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This exam is not available.")
    end

    it "fails when no employee is selected" do
      exam.publish!

      result = described_class.call(exam: exam, employee_ids: [], assigned_by: assigner)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Select at least one employee.")
    end

    it "enqueues one summary job" do
      exam.publish!
      employees = create_list(:employee, 2, company: company)

      expect do
        described_class.call(exam: exam, employee_ids: employees.map(&:id), assigned_by: assigner)
      end.to have_enqueued_job(Exams::SummaryJob).with(exam.id).exactly(:once)
    end
  end
end
