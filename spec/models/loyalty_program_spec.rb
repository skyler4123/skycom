# spec/models/loyalty_program_spec.rb
require "rails_helper"

RSpec.describe LoyaltyProgram, type: :model do
  describe "table" do
    it "uses loyalty_programs" do
      expect(described_class.table_name).to eq("loyalty_programs")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:loyalty_entries).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:earn_rate_bp).only_integer.is_greater_than_or_equal_to(0) }
  end
end
