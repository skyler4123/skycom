# spec/services/exams/grade_attempt_service_spec.rb
require "rails_helper"

RSpec.describe Exams::GradeAttemptService, :active_job do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:grader) { create(:employee, company: company) }
  let(:question) { create(:question, :text, company: company, points: 2) }
  let(:exam) do
    create(:exam, company: company, questions_count: 0).tap do |record|
      record.exam_question_appointments.create!(question: question, position: 0)
      record.publish!
    end
  end
  let(:appointment) { start_exam!(exam, employee) }
  let(:answer) { appointment.employee_question_appointments.first }

  def submit_for_review
    Exams::SaveAnswerService.call(appointment: appointment, answer_id: answer.id, text_answer: "An answer")
    Exams::SubmitAttemptService.call(appointment: appointment)
    appointment.reload
  end

  describe ".call" do
    it "grades text answers and finalizes the attempt" do
      submit_for_review

      result = described_class.call(appointment: appointment, grades: { answer.id.to_s => 2 }, grader: grader)

      expect(result[:success]).to be(true)
      appointment.reload
      answer.reload
      expect(appointment.workflow_status).to eq("graded")
      expect(appointment.score).to eq(100)
      expect(appointment.passed).to be(true)
      expect(appointment.graded_by_employee_id).to eq(grader.id)
      expect(appointment.graded_at).to be_present
      expect(answer.points_awarded).to eq(2)
      expect(answer).to be_correct
    end

    it "supports partial points" do
      submit_for_review

      result = described_class.call(appointment: appointment, grades: { answer.id.to_s => 1 }, grader: grader)

      expect(result[:success]).to be(true)
      appointment.reload
      answer.reload
      expect(appointment.score).to eq(50)
      expect(appointment.passed).to be(false)
      expect(answer.points_awarded).to eq(1)
      expect(answer.correct).to be(false)
    end

    it "fails when the attempt is not submitted" do
      result = described_class.call(appointment: appointment, grades: { answer.id.to_s => 1 }, grader: grader)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This attempt is not waiting for review.")
    end

    it "fails when a text answer is missing a grade" do
      submit_for_review

      result = described_class.call(appointment: appointment, grades: {}, grader: grader)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to include("Grade missing")
    end

    it "fails when points are outside the allowed range" do
      submit_for_review

      result = described_class.call(appointment: appointment, grades: { answer.id.to_s => 3 }, grader: grader)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to include("Points must be between 0 and 2")
    end

    it "fails when the answer does not belong to the attempt" do
      submit_for_review

      result = described_class.call(appointment: appointment, grades: { SecureRandom.uuid => 1 }, grader: grader)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Answer not found.")
    end

    it "enqueues the summary job" do
      submit_for_review

      expect do
        described_class.call(appointment: appointment, grades: { answer.id.to_s => 2 }, grader: grader)
      end.to have_enqueued_job(Exams::SummaryJob).with(exam.id)
    end
  end
end
