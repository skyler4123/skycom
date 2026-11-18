# spec/models/course_spec.rb
require "rails_helper"

RSpec.describe Course, type: :model do
  describe "table" do
    it "uses courses" do
      expect(described_class.table_name).to eq("courses")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:course_lessons).dependent(:destroy) }
    it { should have_many(:course_enrollments).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
