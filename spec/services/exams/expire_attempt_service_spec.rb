# spec/services/exams/expire_attempt_service_spec.rb
require "rails_helper"

RSpec.describe Exams::ExpireAttemptService, :active_job do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:exam) { create(:exam, company: company, duration_minutes: 1) }
  let(:appointment) { start_exam!(exam, employee) }

  describe ".call" do
    it "expires an overdue attempt and grades saved objective answers" do
      answer = appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [ answer.correct_option_ids.first ])

      travel_to(appointment.deadline_at + 1.second) do
        result = described_class.call(appointment: appointment)

        expect(result[:success]).to be(true)
        appointment.reload
        answer.reload
        expect(appointment.workflow_status).to eq("expired")
        expect(appointment.score).to eq(100)
        expect(appointment.passed).to be(false)
        expect(appointment.submitted_at).to be_present
        expect(appointment.graded_at).to be_present
        expect(answer.correct).to be(true)
      end
    end

    it "gives text answers zero points" do
      question = create(:question, :text, company: company)
      text_exam = create(:exam, company: company, questions_count: 0).tap do |record|
        record.exam_question_appointments.create!(question: question, position: 0)
        record.publish!
      end
      text_appointment = start_exam!(text_exam, employee)
      text_answer = text_appointment.employee_question_appointments.first
      Exams::SaveAnswerService.call(appointment: text_appointment, answer_id: text_answer.id, text_answer: "An answer")

      travel_to(text_appointment.deadline_at + 1.second) do
        result = described_class.call(appointment: text_appointment)

        expect(result[:success]).to be(true)
        text_appointment.reload
        text_answer.reload
        expect(text_appointment.workflow_status).to eq("expired")
        expect(text_appointment.score).to eq(0)
        expect(text_appointment.passed).to be(false)
        expect(text_answer.points_awarded).to eq(0)
        expect(text_answer.correct).to be(false)
      end
    end

    it "fails when the attempt is not overdue" do
      result = described_class.call(appointment: appointment)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This attempt is not overdue.")
    end

    it "enqueues the summary job" do
      travel_to(appointment.deadline_at + 1.second) do
        expect do
          described_class.call(appointment: appointment)
        end.to have_enqueued_job(Exams::SummaryJob).with(exam.id)
      end
    end
  end
end
