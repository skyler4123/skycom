# spec/models/exam_question_appointment_spec.rb
require "rails_helper"

RSpec.describe ExamQuestionAppointment, type: :model do
  let(:exam) { create(:exam) }
  let(:question) { create(:question, company: exam.company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:exam) }
    it { should belong_to(:question) }
  end

  describe "validations" do
    it "is valid with a question and position" do
      expect(build(:exam_question_appointment, exam: exam, question: question, position: 0)).to be_valid
    end

    it "rejects a negative position" do
      expect(build(:exam_question_appointment, exam: exam, question: question, position: -1)).not_to be_valid
    end

    it "rejects the same question twice in one exam" do
      create(:exam_question_appointment, exam: exam, question: question, position: 0)
      duplicate = build(:exam_question_appointment, exam: exam, question: question, position: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:question_id]).to be_present
    end
  end

  it "derives company from the exam" do
    row = create(:exam_question_appointment, exam: exam, question: question)
    expect(row.company_id).to eq(exam.company_id)
  end
end
