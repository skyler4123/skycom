# spec/models/ledger_account_spec.rb
require "rails_helper"

RSpec.describe LedgerAccount, type: :model do
  describe "table" do
    it "uses ledger_accounts" do
      expect(described_class.table_name).to eq("ledger_accounts")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:parent).class_name("LedgerAccount").optional }
    it { should have_many(:children).class_name("LedgerAccount").dependent(:restrict_with_error) }
    it { should have_many(:journal_lines).dependent(:restrict_with_error) }
    it { should have_many(:budget_lines).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:code) }
    it { should validate_length_of(:code).is_at_most(32) }
    it "declares code uniqueness scoped to company_id" do
      validator = described_class.validators_on(:code).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:account_type).with_prefix(true).with_values(asset: 0, liability: 1, equity: 2, revenue: 3, expense: 4) }
    it { should define_enum_for(:normal_balance).with_prefix(true).with_values(debit: 0, credit: 1) }
  end
end
