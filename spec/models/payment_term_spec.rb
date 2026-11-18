# spec/models/payment_term_spec.rb
require "rails_helper"

RSpec.describe PaymentTerm, type: :model do
  describe "table" do
    it "uses payment_terms" do
      expect(described_class.table_name).to eq("payment_terms")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it "declares name uniqueness scoped to company_id" do
      validator = described_class.validators_on(:name).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_numericality_of(:net_days).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:discount_days).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

describe "due dates" do
  it "derives the due date from net days" do
    term = described_class.new(net_days: 30)

    expect(term.due_date_for(Date.new(2026, 1, 1))).to eq(Date.new(2026, 1, 31))
  end

  it "has no discount deadline when no discount is offered" do
    expect(described_class.new(net_days: 30).discount_deadline_for(Date.new(2026, 1, 1))).to be_nil
  end
end
end
