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
    it "mirrors CREDIT_USAGE_RATES keys" do
      described_class::VALID_ACTION_TYPES.each do |action|
        expect(CREDIT_USAGE_RATES).to have_key(action.to_sym)
      end
    end
  end
end
