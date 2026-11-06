# spec/models/question_spec.rb
require "rails_helper"

RSpec.describe Question, type: :model do
  let(:company) { create(:company) }
  let(:question) { build(:question, company: company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should have_many(:question_options).dependent(:destroy) }
    it { should have_many(:exam_question_appointments).dependent(:destroy) }
    it { should have_many(:employee_question_appointments).dependent(:destroy) }
  end

  describe "validations" do
    it "is valid with the default factory" do
      expect(question).to be_valid
    end

    it "requires a name" do
      question.name = nil
      expect(question).not_to be_valid
      expect(question.errors[:name]).to include("can't be blank")
    end

    it "requires points greater than zero" do
      question.points = 0
      expect(question).not_to be_valid
      expect(question.errors[:points]).to be_present
    end

    it "requires a category from the same company" do
      other_company = create(:company)
      question.category = create(:category, company: other_company, resource_name: "questions")
      expect(question).not_to be_valid
      expect(question.errors[:category]).to include("must belong to the same company")
    end

    it "requires a category with resource_name questions" do
      question.category = create(:category, company: company, resource_name: "products")
      expect(question).not_to be_valid
      expect(question.errors[:category]).to include("must be a question category")
    end

    it "requires at least two options for a single-choice question" do
      question.question_options = [ question.question_options.first ]
      expect(question).not_to be_valid
      expect(question.errors[:question_options]).to include("must have at least two options")
    end

    it "requires exactly one correct option for a single-choice question" do
      question.question_options.each { |option| option.correct = false }
      expect(question).not_to be_valid
      expect(question.errors[:question_options]).to include("must have exactly one correct option")
    end

    it "rejects more than one correct option" do
      question.question_options[1].correct = true
      expect(question).not_to be_valid
      expect(question.errors[:question_options]).to include("must have exactly one correct option")
    end

    it "requires exactly two options for a true/false question" do
      question = build(:question, :true_false, company: company)
      question.question_options.build(content: "Maybe", correct: false, position: 2)
      expect(question).not_to be_valid
      expect(question.errors[:question_options]).to include("must have exactly two options")
    end

    it "requires text questions to have no options" do
      question = build(:question, :text, company: company)
      question.question_options.build(content: "Unexpected", correct: true, position: 0)
      expect(question).not_to be_valid
      expect(question.errors[:question_options]).to include("must be empty for text questions")
    end

    it "allows correct_text on text questions" do
      question = build(:question, :text, company: company)
      question.correct_text = "A model answer"
      expect(question).to be_valid
    end

    it "rejects correct_text on choice questions" do
      question.correct_text = "Not allowed"
      expect(question).not_to be_valid
      expect(question.errors[:correct_text]).to include("must be blank for choice questions")
    end
  end

  describe "#shuffleable?" do
    it "is true for single-choice questions" do
      expect(build(:question, company: company)).to be_shuffleable
    end

    it "is false for true/false and text questions" do
      expect(build(:question, :true_false, company: company)).not_to be_shuffleable
      expect(build(:question, :text, company: company)).not_to be_shuffleable
    end
  end

  describe "#correct_option" do
    it "returns the option marked correct" do
      expect(question.correct_option).to be_correct
    end
  end
end
