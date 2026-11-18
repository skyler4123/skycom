# spec/models/budget_line_spec.rb
require "rails_helper"

RSpec.describe BudgetLine, type: :model do
  describe "table" do
    it "uses budget_lines" do
      expect(described_class.table_name).to eq("budget_lines")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:budget) }
    it { should belong_to(:ledger_account) }
  end

  describe "validations" do
    it { should validate_presence_of(:period_month) }
    it { should validate_numericality_of(:amount_cents).only_integer }
    it "declares ledger_account_id uniqueness scoped to budget_id, period_month" do
      validator = described_class.validators_on(:ledger_account_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[budget_id period_month])
    end
  end
end
