# spec/models/question_option_spec.rb
require "rails_helper"

RSpec.describe QuestionOption, type: :model do
  let(:question) { create(:question) }
  let(:option) { build(:question_option, question: question, content: "Choice") }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:question) }
  end

  describe "validations" do
    it "is valid with content" do
      expect(option).to be_valid
    end

    it "requires content" do
      option.content = nil
      expect(option).not_to be_valid
      expect(option.errors[:content]).to include("can't be blank")
    end

    it "requires a non-negative position" do
      option.position = -1
      expect(option).not_to be_valid
      expect(option.errors[:position]).to be_present
    end
  end

  it "derives company from the question" do
    option.save!
    expect(option.company_id).to eq(question.company_id)
  end
end
