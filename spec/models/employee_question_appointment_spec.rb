# spec/models/employee_question_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeQuestionAppointment, type: :model do
  let(:exam) { create(:exam) }
  let(:employee_exam_appointment) { create(:employee_exam_appointment, exam: exam) }
  let(:answer) { create(:employee_question_appointment, employee_exam_appointment: employee_exam_appointment) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee_exam_appointment) }
    it { should belong_to(:question) }
  end

  describe "validations" do
    it "is valid with the default factory" do
      expect(answer).to be_valid
    end

    it "rejects selected options outside the snapshot" do
      answer.selected_option_ids = [ SecureRandom.uuid ]
      expect(answer).not_to be_valid
      expect(answer.errors[:selected_option_ids]).to include("contains an option outside the question snapshot")
    end

    it "rejects more than one selection for a choice question" do
      answer.selected_option_ids = answer.snapshot_options.first(2).map { |option| option["id"] }
      expect(answer).not_to be_valid
      expect(answer.errors[:selected_option_ids]).to include("must have at most one option")
    end

    it "rejects points awarded above points possible" do
      answer.points_awarded = answer.points_possible + 1
      expect(answer).not_to be_valid
      expect(answer.errors[:points_awarded]).to be_present
    end
  end

  describe "#grade_objective!" do
    it "awards full points for the correct option" do
      answer.update!(selected_option_ids: [ answer.correct_option_ids.first ])
      answer.grade_objective!
      expect(answer.correct).to be(true)
      expect(answer.points_awarded).to eq(answer.points_possible)
    end

    it "awards zero for an incorrect option" do
      wrong_id = answer.snapshot_options.find { |option| !option["correct"] }["id"]
      answer.update!(selected_option_ids: [ wrong_id ])
      answer.grade_objective!
      expect(answer.correct).to be(false)
      expect(answer.points_awarded).to eq(0)
    end
  end

  describe "#grade_text!" do
    let(:text_question) { create(:question, :text, company: exam.company) }
    let(:text_answer) do
      create(
        :employee_question_appointment,
        employee_exam_appointment: employee_exam_appointment,
        question: text_question,
        question_type: :text,
        points_possible: text_question.points
      )
    end

    it "marks full points as correct" do
      text_answer.grade_text!(text_answer.points_possible)
      expect(text_answer.correct).to be(true)
      expect(text_answer.points_awarded).to eq(text_answer.points_possible)
    end

    it "marks partial points as incorrect" do
      text_answer.grade_text!(text_answer.points_possible - 1)
      expect(text_answer.correct).to be(false)
      expect(text_answer.points_awarded).to eq(text_answer.points_possible - 1)
    end
  end

  describe "snapshot readers" do
    it "returns ordered options and the correct option ids" do
      expect(answer.snapshot_options).to be_present
      expect(answer.option_order_ids).to eq(answer.option_order)
      expect(answer.display_options.map { |option| option["id"] }).to eq(answer.option_order)
      expect(answer.correct_option_ids.size).to eq(1)
    end

    it "reports answered for a selection or text" do
      expect(answer.answered?).to be(false)
      answer.selected_option_ids = [ answer.snapshot_options.first["id"] ]
      expect(answer.answered?).to be(true)
    end
  end
end
