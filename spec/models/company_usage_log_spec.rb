# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyUsageLog, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:company_wallet) }
    it { should belong_to(:source).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:action_type) }
    it { should validate_presence_of(:change_amount) }
    it { should validate_presence_of(:balance_after) }
    it { should validate_numericality_of(:change_amount).only_integer }
  end

  describe "action type catalog" do
    it "includes every page deduction action type" do
      CREDIT_DEDUCTION_ACTION_TYPES.each do |key|
        expect(described_class::VALID_ACTION_TYPES).to include(key)
      end
    end

    it "includes the wallet movement defaults (top_up, deduction)" do
      expect(described_class::VALID_ACTION_TYPES).to include("top_up", "deduction")
    end

    it "has no duplicate entries" do
      expect(described_class::VALID_ACTION_TYPES.uniq).to eq(described_class::VALID_ACTION_TYPES)
    end
  end
end
