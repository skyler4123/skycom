# spec/models/course_enrollment_spec.rb
require "rails_helper"

RSpec.describe CourseEnrollment, type: :model do
  describe "table" do
    it "uses course_enrollments" do
      expect(described_class.table_name).to eq("course_enrollments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:course) }
    it { should belong_to(:employee) }
    it { should belong_to(:exam).optional }
  end

  describe "validations" do
    it "declares employee_id uniqueness scoped to course_id" do
      validator = described_class.validators_on(:employee_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[course_id])
    end
    it { should validate_numericality_of(:progress_percent).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(enrolled: 0, in_progress: 1, completed: 2, expired: 3, dropped: 4) }
  end

describe "#expired?" do
  it "reports expiry from the certification date" do
    expect(described_class.new(expires_on: Date.current - 1)).to be_expired
    expect(described_class.new(expires_on: Date.current + 1)).not_to be_expired
  end
end
end
