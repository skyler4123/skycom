# spec/services/exams/submit_attempt_service_spec.rb
require "rails_helper"

RSpec.describe Exams::SubmitAttemptService, :active_job do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:exam) { create(:exam, company: company) }
  let(:appointment) { start_exam!(exam, employee) }
  let(:answer) { appointment.employee_question_appointments.first }

  def exam_with_question(question)
    new_exam = create(:exam, company: company, questions_count: 0)
    new_exam.exam_question_appointments.create!(question: question, position: 0)
    new_exam.publish!
    new_exam
  end

  def correct_option_id(answer)
    answer.correct_option_ids.first
  end

  describe ".call" do
    it "saves final answers and grades an objective-only attempt" do
      result = described_class.call(
        appointment: appointment,
        answers: [ { id: answer.id, selected_option_ids: [ correct_option_id(answer) ] } ]
      )

      expect(result[:success]).to be(true)
      appointment.reload
      expect(appointment.workflow_status).to eq("graded")
      expect(appointment.score).to eq(100)
      expect(appointment.passed).to be(true)
      expect(appointment.submitted_at).to be_present
      expect(appointment.graded_at).to be_present
      expect(answer.reload.correct).to be(true)
    end

    it "scores unanswered objective questions as zero" do
      result = described_class.call(appointment: appointment)

      expect(result[:success]).to be(true)
      appointment.reload
      expect(appointment.workflow_status).to eq("graded")
      expect(appointment.score).to eq(0)
      expect(appointment.passed).to be(false)
    end

    it "marks a text exam as submitted for review" do
      question = create(:question, :text, company: company)
      text_exam = exam_with_question(question)
      text_appointment = start_exam!(text_exam, employee)
      text_answer = text_appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: text_appointment, answer_id: text_answer.id, text_answer: "An answer")

      result = described_class.call(appointment: text_appointment)

      expect(result[:success]).to be(true)
      text_appointment.reload
      expect(text_appointment.workflow_status).to eq("submitted")
      expect(text_appointment.score).to be_nil
      expect(text_appointment.passed).to be_nil
      expect(text_appointment.submitted_at).to be_present
      expect(text_appointment.earned_points).to eq(0)
    end

    it "fails when the attempt is not in progress" do
      appointment.update!(workflow_status: :assigned)

      result = described_class.call(appointment: appointment)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This attempt is not in progress.")
    end

    it "expires an attempt submitted after the grace period" do
      exam.update!(duration_minutes: 1)
      expiring_appointment = start_exam!(exam.reload, employee)
      travel_to(expiring_appointment.deadline_at + Exams::SubmitAttemptService::GRACE_PERIOD + 1.second) do
        result = described_class.call(appointment: expiring_appointment)

        expect(result[:success]).to be(false)
        expect(result[:expired]).to be(true)
        expect(expiring_appointment.reload.workflow_status).to eq("expired")
      end
    end

    it "enqueues the summary job" do
      appointment

      expect do
        described_class.call(appointment: appointment)
      end.to have_enqueued_job(Exams::SummaryJob).with(exam.id)
    end
  end
end
