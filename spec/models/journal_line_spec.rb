# spec/models/journal_line_spec.rb
require "rails_helper"

RSpec.describe JournalLine, type: :model do
  describe "table" do
    it "uses journal_lines" do
      expect(described_class.table_name).to eq("journal_lines")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:journal_entry) }
    it { should belong_to(:ledger_account) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:department).optional }
    it { should belong_to(:cost_center).optional }
    it { should belong_to(:employee).optional }
    it { should belong_to(:customer).optional }
    it { should belong_to(:supplier).optional }
    it { should belong_to(:product).optional }
    it { should belong_to(:project).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:debit_cents).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:fx_rate).is_greater_than(0) }
  end

describe "double-entry rules" do
  it "accepts a debit-only line" do
    line = described_class.new(debit_cents: 500, credit_cents: 0)
    line.valid?

    expect(line.errors[:base]).to eq([])
  end

  it "rejects a line that debits and credits at once" do
    line = described_class.new(debit_cents: 500, credit_cents: 500)
    line.valid?

    expect(line.errors[:base]).to include("must debit or credit exactly one side")
  end

  it "rejects a line with no amount on either side" do
    line = described_class.new(debit_cents: 0, credit_cents: 0)
    line.valid?

    expect(line.errors[:base]).to include("must debit or credit exactly one side")
  end

  it "reports a signed amount for a trial balance" do
    expect(described_class.new(debit_cents: 700).signed_amount_cents).to eq(700)
    expect(described_class.new(credit_cents: 700).signed_amount_cents).to eq(-700)
  end
end
end
