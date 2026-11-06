# spec/services/exams/summary_service_spec.rb
require "rails_helper"

RSpec.describe Exams::SummaryService do
  let(:exam) { create(:exam) }
  let(:company) { exam.company }

  def create_employee
    create(:employee, company: company)
  end

  def create_appointment(employee, workflow_status:, score: nil, passed: nil, attempt_number: 1, started_at: 1.hour.ago, submitted_at: 30.minutes.ago)
    create(
      :employee_exam_appointment,
      exam: exam,
      employee: employee,
      workflow_status: workflow_status,
      score: score,
      passed: passed,
      attempt_number: attempt_number,
      started_at: started_at,
      submitted_at: submitted_at,
      graded_at: workflow_status == :graded ? 20.minutes.ago : nil
    )
  end

  describe ".call" do
    it "computes per-employee counts and score statistics" do
      passed_employee = create_employee
      failed_employee = create_employee
      pending_employee = create_employee
      expired_employee = create_employee
      cancelled_employee = create_employee

      create_appointment(passed_employee, workflow_status: :graded, score: 80, passed: true, attempt_number: 1)
      create_appointment(passed_employee, workflow_status: :graded, score: 50, passed: false, attempt_number: 2)
      create_appointment(failed_employee, workflow_status: :graded, score: 40, passed: false)
      create_appointment(pending_employee, workflow_status: :submitted)
      create_appointment(expired_employee, workflow_status: :expired, score: 0, passed: false)
      create_appointment(cancelled_employee, workflow_status: :cancelled, started_at: nil, submitted_at: nil)

      summary = described_class.call(exam: exam)

      expect(summary.assigned_count).to eq(4)
      expect(summary.started_count).to eq(4)
      expect(summary.submitted_count).to eq(4)
      expect(summary.graded_count).to eq(2)
      expect(summary.passed_count).to eq(1)
      expect(summary.failed_count).to eq(1)
      expect(summary.pending_review_count).to eq(1)
      expect(summary.expired_count).to eq(1)
      expect(summary.average_score).to eq(60)
      expect(summary.highest_score).to eq(80)
      expect(summary.lowest_score).to eq(40)
      expect(summary.pass_rate).to eq(50)
      expect(summary.computed_at).to be_present
    end

    it "counts an employee as passed when a retake succeeds" do
      employee = create_employee
      create_appointment(employee, workflow_status: :graded, score: 50, passed: false, attempt_number: 1)
      create_appointment(employee, workflow_status: :graded, score: 80, passed: true, attempt_number: 2)

      summary = described_class.call(exam: exam)

      expect(summary.passed_count).to eq(1)
      expect(summary.failed_count).to eq(0)
      expect(summary.average_score).to eq(80)
      expect(summary.highest_score).to eq(80)
      expect(summary.lowest_score).to eq(80)
    end

    it "does not downgrade an employee who passed before a failed retake" do
      employee = create_employee
      create_appointment(employee, workflow_status: :graded, score: 80, passed: true, attempt_number: 1)
      create_appointment(employee, workflow_status: :graded, score: 50, passed: false, attempt_number: 2)

      summary = described_class.call(exam: exam)

      expect(summary.passed_count).to eq(1)
      expect(summary.failed_count).to eq(0)
      expect(summary.average_score).to eq(80)
    end

    it "counts expired attempts separately from failures" do
      employee = create_employee
      create_appointment(employee, workflow_status: :expired, score: 0, passed: false)

      summary = described_class.call(exam: exam)

      expect(summary.assigned_count).to eq(1)
      expect(summary.graded_count).to eq(0)
      expect(summary.failed_count).to eq(0)
      expect(summary.expired_count).to eq(1)
      expect(summary.pass_rate).to be_nil
    end

    it "excludes cancelled attempts" do
      employee = create_employee
      create_appointment(employee, workflow_status: :cancelled, started_at: nil, submitted_at: nil)

      summary = described_class.call(exam: exam)

      expect(summary.assigned_count).to eq(0)
      expect(summary.started_count).to eq(0)
      expect(summary.submitted_count).to eq(0)
    end

    it "computes question stats from graded answers only" do
      question = exam.questions.first
      correct_employee = create_employee
      incorrect_employee = create_employee
      pending_employee = create_employee

      correct_appointment = create_appointment(correct_employee, workflow_status: :graded, score: 100, passed: true)
      incorrect_appointment = create_appointment(incorrect_employee, workflow_status: :graded, score: 0, passed: false)
      pending_appointment = create_appointment(pending_employee, workflow_status: :submitted)

      create(:employee_question_appointment, employee_exam_appointment: correct_appointment, question: question, correct: true, points_possible: 1, points_awarded: 1)
      create(:employee_question_appointment, employee_exam_appointment: incorrect_appointment, question: question, correct: false, points_possible: 1, points_awarded: 0)
      create(:employee_question_appointment, employee_exam_appointment: pending_appointment, question: question, correct: true, points_possible: 1, points_awarded: 1)

      summary = described_class.call(exam: exam)

      stats = summary.question_stats[question.id]
      expect(stats["answered_count"]).to eq(2)
      expect(stats["correct_count"]).to eq(1)
      expect(stats["correct_rate"]).to eq(50)
    end

    it "is idempotent and reuses the same summary row" do
      employee = create_employee
      create_appointment(employee, workflow_status: :graded, score: 80, passed: true)

      first = described_class.call(exam: exam)
      second = described_class.call(exam: exam)

      expect(second.id).to eq(first.id)
      expect(ExamSummary.where(exam: exam).count).to eq(1)
      expect(second.reload.computed_at).to be_present
      expect(second.passed_count).to eq(1)
    end
  end
end
