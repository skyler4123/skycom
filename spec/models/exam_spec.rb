# spec/models/exam_spec.rb
require "rails_helper"

RSpec.describe Exam, type: :model do
  let(:company) { create(:company) }
  let(:exam) { create(:exam, company: company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:exam_question_appointments).dependent(:destroy) }
    it { should have_many(:employee_exam_appointments).dependent(:destroy) }
    it { should have_one(:exam_summary).dependent(:destroy) }
  end

  describe "validations" do
    it "is valid with the default factory" do
      expect(exam).to be_valid
    end

    it "requires a name" do
      exam.name = nil
      expect(exam).not_to be_valid
      expect(exam.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name per company" do
      create(:exam, company: company, name: "Unique exam")
      duplicate = build(:exam, company: company, name: "Unique exam")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "allows a nil duration" do
      expect(build(:exam, company: company, duration_minutes: nil)).to be_valid
    end

    it "rejects a non-positive duration" do
      expect(build(:exam, company: company, duration_minutes: 0)).not_to be_valid
    end

    it "requires passing_score between 0 and 100" do
      expect(build(:exam, company: company, passing_score: 0)).to be_valid
      expect(build(:exam, company: company, passing_score: 100)).to be_valid
      expect(build(:exam, company: company, passing_score: -1)).not_to be_valid
      expect(build(:exam, company: company, passing_score: 101)).not_to be_valid
    end

    it "allows nil max_attempts (unlimited)" do
      expect(build(:exam, company: company, max_attempts: nil)).to be_valid
    end

    it "rejects a non-positive max_attempts" do
      expect(build(:exam, company: company, max_attempts: 0)).not_to be_valid
    end
  end

  describe "#publish!" do
    it "raises when the exam has no questions" do
      empty_exam = create(:exam, company: company, questions_count: 0)
      expect { empty_exam.publish! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(empty_exam.errors.full_messages).to include("Add at least one question before publishing")
    end

    it "sets published status and published_at when questions exist" do
      exam.publish!
      expect(exam.workflow_status).to eq("published")
      expect(exam.published_at).to be_present
    end
  end

  describe "#archive!" do
    it "sets archived status" do
      exam.archive!
      expect(exam.workflow_status).to eq("archived")
    end
  end

  describe "status predicates" do
    it "reports draft, published, and archived" do
      expect(exam).to be_draft
      expect(exam).not_to be_published

      exam.publish!
      expect(exam).to be_published

      exam.archive!
      expect(exam).to be_archived
    end
  end

  describe "#assignable?" do
    it "is true only for published exams" do
      expect(exam).not_to be_assignable
      exam.publish!
      expect(exam).to be_assignable
    end
  end

  describe "#time_limit?" do
    it "is true when duration_minutes is present" do
      expect(exam).to be_time_limit
      expect(build(:exam, company: company, duration_minutes: nil)).not_to be_time_limit
    end
  end

  describe "#attempts_used_for" do
    let(:employee) { create(:employee, company: company) }

    it "counts non-cancelled attempts only" do
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :assigned)
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 2, workflow_status: :cancelled)
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 3, workflow_status: :graded)

      expect(exam.attempts_used_for(employee)).to eq(2)
    end
  end

  describe "#max_attempts_reached_for?" do
    let(:employee) { create(:employee, company: company) }

    before do
      create(:employee_exam_appointment, exam: exam, employee: employee, attempt_number: 1, workflow_status: :assigned)
    end

    it "is true when the limit is reached" do
      exam.update!(max_attempts: 1)
      expect(exam.max_attempts_reached_for?(employee)).to be(true)
    end

    it "is false when attempts remain" do
      exam.update!(max_attempts: 2)
      expect(exam.max_attempts_reached_for?(employee)).to be(false)
    end

    it "is false when the limit is unlimited" do
      exam.update!(max_attempts: nil)
      expect(exam.max_attempts_reached_for?(employee)).to be(false)
    end
  end
end
