# spec/services/exams/save_answer_service_spec.rb
require "rails_helper"

RSpec.describe Exams::SaveAnswerService do
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

  describe ".call" do
    it "saves a single-choice selection" do
      option_id = answer.snapshot_options.first["id"]

      result = described_class.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [ option_id ])

      expect(result[:success]).to be(true)
      expect(answer.reload.selected_option_ids).to eq([ option_id ])
    end

    it "saves a true/false selection" do
      question = create(:question, :true_false, company: company)
      true_false_exam = exam_with_question(question)
      true_false_appointment = start_exam!(true_false_exam, employee)
      true_false_answer = true_false_appointment.employee_question_appointments.first
      option_id = true_false_answer.snapshot_options.first["id"]

      result = described_class.call(appointment: true_false_appointment, answer_id: true_false_answer.id, selected_option_ids: [ option_id ])

      expect(result[:success]).to be(true)
      expect(true_false_answer.reload.selected_option_ids).to eq([ option_id ])
    end

    it "saves a text answer and clears selections" do
      question = create(:question, :text, company: company)
      text_exam = exam_with_question(question)
      text_appointment = start_exam!(text_exam, employee)
      text_answer = text_appointment.employee_question_appointments.first

      result = described_class.call(appointment: text_appointment, answer_id: text_answer.id, selected_option_ids: [ "ignored" ], text_answer: "My answer")

      expect(result[:success]).to be(true)
      expect(text_answer.reload.text_answer).to eq("My answer")
      expect(text_answer.selected_option_ids).to eq([])
    end

    it "clears a choice answer" do
      result = described_class.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [])

      expect(result[:success]).to be(true)
      expect(answer.reload.selected_option_ids).to eq([])
    end

    it "fails when the attempt is not in progress" do
      appointment.update!(workflow_status: :graded)

      result = described_class.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [])

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("This attempt is not in progress.")
    end

    it "fails when the attempt has expired" do
      appointment.update_columns(deadline_at: 1.minute.ago)

      result = described_class.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [])

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Time is up.")
    end

    it "fails when the answer does not belong to the attempt" do
      result = described_class.call(appointment: appointment, answer_id: SecureRandom.uuid, selected_option_ids: [])

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Answer not found.")
    end

    it "fails when the option is outside the snapshot" do
      result = described_class.call(appointment: appointment, answer_id: answer.id, selected_option_ids: [ SecureRandom.uuid ])

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Selected option does not belong to this question.")
    end

    it "fails when more than one option is selected for a single-choice question" do
      result = described_class.call(
        appointment: appointment,
        answer_id: answer.id,
        selected_option_ids: answer.snapshot_options.first(2).map { |option| option["id"] }
      )

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Select only one option.")
    end
  end
end
