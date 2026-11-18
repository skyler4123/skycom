# spec/models/fiscal_period_spec.rb
require "rails_helper"

RSpec.describe FiscalPeriod, type: :model do
  describe "table" do
    it "uses fiscal_periods" do
      expect(described_class.table_name).to eq("fiscal_periods")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:closed_by_employee).class_name("Employee").optional }
    it { should have_many(:journal_entries).dependent(:restrict_with_error) }
    it { should have_many(:depreciation_entries).dependent(:restrict_with_error) }
    it { should have_many(:budgets).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_numericality_of(:fiscal_year).only_integer.is_greater_than(0) }
    it "declares period_no uniqueness scoped to company_id, fiscal_year" do
      validator = described_class.validators_on(:period_no).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id fiscal_year])
    end
    it { should validate_presence_of(:starts_on) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(open: 0, locked: 1, closed: 2) }
  end

describe "date window" do
  it "rejects an end date before the start date" do
    period = described_class.new(starts_on: Date.new(2026, 2, 1), ends_on: Date.new(2026, 1, 1))
    period.valid?

    expect(period.errors[:ends_on]).to include("must be on or after the start date")
  end

  it "accepts a same-day period" do
    period = described_class.new(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 1, 1))
    period.valid?

    expect(period.errors[:ends_on]).to eq([])
  end

  it "knows whether a date falls inside it" do
    period = described_class.new(starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 1, 31))

    expect(period.covers?(Date.new(2026, 1, 15))).to be(true)
    expect(period.covers?(Date.new(2026, 2, 1))).to be(false)
  end
end
end
