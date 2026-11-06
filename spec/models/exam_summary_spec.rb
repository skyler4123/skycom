# spec/models/exam_summary_spec.rb
require "rails_helper"

RSpec.describe ExamSummary, type: :model do
  let(:exam) { create(:exam) }
  let(:summary) { build(:exam_summary, exam: exam) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:exam) }
  end

  describe "validations" do
    it "is valid with the default factory" do
      expect(summary).to be_valid
    end

    it "rejects negative counts" do
      summary.passed_count = -1
      expect(summary).not_to be_valid
      expect(summary.errors[:passed_count]).to be_present
    end

    it "rejects scores outside 0..100" do
      summary.average_score = 101
      expect(summary).not_to be_valid
      expect(summary.errors[:average_score]).to be_present
    end

    it "rejects a duplicate summary for the same exam" do
      create(:exam_summary, exam: exam)
      duplicate = build(:exam_summary, exam: exam)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:exam_id]).to be_present
    end
  end
end
