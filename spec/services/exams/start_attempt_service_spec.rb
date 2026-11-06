# spec/services/exams/start_attempt_service_spec.rb
require "rails_helper"

RSpec.describe Exams::StartAttemptService, :active_job do
  let(:exam) { create(:exam, duration_minutes: 30) }
  let(:employee) { create(:employee, company: exam.company) }

  describe ".call" do
    it "starts an assigned attempt and snapshots every question" do
      publish_exam!(exam)
      assignment = assign_exam!(exam, employee)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(true)
      appointment = result[:appointment].reload
      expect(appointment.id).to eq(assignment.id)
      expect(appointment.workflow_status).to eq("in_progress")
      expect(appointment.started_at).to be_present
      expect(appointment.deadline_at).to be_within(1.second).of(appointment.started_at + 30.minutes)
      expect(appointment.employee_question_appointments.count).to eq(exam.exam_question_appointments.count)

      appointment.employee_question_appointments.each do |answer|
        question = exam.questions.find(answer.question_id)
        expect(answer.question_snapshot["name"]).to eq(question.name)
        expect(answer.question_snapshot["options"].map { |option| option["content"] }).to match_array(question.question_options.map(&:content))
        expect(answer.points_possible).to eq(question.points)
        expect(answer.option_order.sort).to eq(question.question_options.map(&:id).sort)
      end
    end

    it "preserves option position order when shuffle_options is false" do
      exam.update!(shuffle_options: false)
      appointment = start_exam!(exam, employee)

      appointment.employee_question_appointments.each do |answer|
        question = exam.questions.find(answer.question_id)
        expect(answer.option_order).to eq(question.question_options.order(:position).pluck(:id))
      end
    end

    it "uses a permutation of option ids when shuffle_options is true" do
      exam.update!(shuffle_options: true)
      appointment = start_exam!(exam, employee)

      appointment.employee_question_appointments.each do |answer|
        question = exam.questions.find(answer.question_id)
        expect(answer.option_order.sort).to eq(question.question_options.map(&:id).sort)
      end
    end

    it "creates a new attempt for a retake" do
      exam.update!(max_attempts: 2)
      publish_exam!(exam)
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :graded)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(true)
      expect(result[:appointment].attempt_number).to eq(2)
      expect(result[:appointment].workflow_status).to eq("in_progress")
    end

    it "leaves deadline_at nil when the exam has no time limit" do
      exam.update!(duration_minutes: nil)
      appointment = start_exam!(exam, employee)

      expect(appointment.deadline_at).to be_nil
    end

    it "fails for a draft exam" do
      assign_exam!(exam, employee)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This exam is not available.")
    end

    it "fails for an archived exam" do
      publish_exam!(exam)
      exam.archive!
      assign_exam!(exam, employee)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This exam is not available.")
    end

    it "fails when the employee is not assigned" do
      publish_exam!(exam)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("You are not assigned to this exam.")
    end

    it "fails when the exam has no questions" do
      empty_exam = create(:exam, company: exam.company, questions_count: 0)
      empty_exam.update_column(:workflow_status, Exam.workflow_statuses[:published])
      assign_exam!(empty_exam, employee)

      result = described_class.call(exam: empty_exam, employee: employee)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This exam has no questions.")
    end

    it "fails when an active attempt already exists" do
      publish_exam!(exam)
      active = create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :in_progress)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(false)
      expect(result[:active_appointment_id]).to eq(active.id)
      expect(result[:errors]).to include("You already have an attempt in progress.")
    end

    it "fails when the attempt limit is reached" do
      exam.update!(max_attempts: 1)
      publish_exam!(exam)
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :graded)

      result = described_class.call(exam: exam, employee: employee)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("You have used all allowed attempts for this exam.")
    end

    it "enqueues the summary job" do
      publish_exam!(exam)
      assign_exam!(exam, employee)

      expect do
        described_class.call(exam: exam, employee: employee)
      end.to have_enqueued_job(Exams::SummaryJob).with(exam.id)
    end
  end
end
