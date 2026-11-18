# spec/models/project_time_entry_spec.rb
require "rails_helper"

RSpec.describe ProjectTimeEntry, type: :model do
  describe "table" do
    it "uses project_time_entries" do
      expect(described_class.table_name).to eq("project_time_entries")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:project) }
    it { should belong_to(:task).optional }
    it { should belong_to(:employee) }
    it { should belong_to(:invoice).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:worked_on) }
    it { should validate_numericality_of(:minutes).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:rate_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

describe "#amount_cents" do
  it "prices minutes at the snapshotted rate" do
    entry = described_class.new(minutes: 90, rate_cents: 60_000)

    expect(entry.amount_cents).to eq(90_000)
  end
end
end
