# spec/models/journal_entry_spec.rb
require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  describe "table" do
    it "uses journal_entries" do
      expect(described_class.table_name).to eq("journal_entries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:fiscal_period).optional }
    it { should belong_to(:source).optional }
    it { should belong_to(:posted_by_employee).class_name("Employee").optional }
    it { should belong_to(:reversal_of).class_name("JournalEntry").optional }
    it { should have_many(:journal_lines).dependent(:destroy) }
    it { should have_one(:reversal_entry).class_name("JournalEntry") }
  end

  describe "validations" do
    it { should validate_presence_of(:entry_date) }
    it { should validate_presence_of(:event_key) }
    it { should validate_length_of(:event_key).is_at_most(64) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, posted: 1, reversed: 2) }
  end

describe "#balanced?" do
  it "is balanced when debits equal credits" do
    entry = described_class.new
    entry.journal_lines.build(debit_cents: 1_000)
    entry.journal_lines.build(credit_cents: 1_000)

    expect(entry).to be_balanced
  end

  it "is unbalanced when the legs differ" do
    entry = described_class.new
    entry.journal_lines.build(debit_cents: 1_000)
    entry.journal_lines.build(credit_cents: 900)

    expect(entry).not_to be_balanced
  end
end
end
