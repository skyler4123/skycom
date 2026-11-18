# spec/models/course_lesson_spec.rb
require "rails_helper"

RSpec.describe CourseLesson, type: :model do
  describe "table" do
    it "uses course_lessons" do
      expect(described_class.table_name).to eq("course_lessons")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:course) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than(0) }
    it "declares position uniqueness scoped to course_id" do
      validator = described_class.validators_on(:position).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[course_id])
    end
  end
end
