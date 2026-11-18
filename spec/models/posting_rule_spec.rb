# spec/models/posting_rule_spec.rb
require "rails_helper"

RSpec.describe PostingRule, type: :model do
  describe "table" do
    it "uses posting_rules" do
      expect(described_class.table_name).to eq("posting_rules")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:debit_ledger_account).class_name("LedgerAccount") }
    it { should belong_to(:credit_ledger_account).class_name("LedgerAccount") }
  end

  describe "validations" do
    it { should validate_presence_of(:event_key) }
    it { should validate_length_of(:event_key).is_at_most(64) }
    it "declares event_key uniqueness scoped to company_id, priority" do
      validator = described_class.validators_on(:event_key).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id priority])
    end
    it { should validate_numericality_of(:priority).only_integer }
  end
end
