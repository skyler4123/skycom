# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyWalletLog, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:company_wallet) }
    it { should belong_to(:source).optional }
  end

  describe "enums" do
    it { should define_enum_for(:change_type).with_values(credit: 0, debit: 1, refund: 2, adjustment: 3) }
  end

  describe "validations" do
    it { should validate_presence_of(:change_amount) }
    it { should validate_presence_of(:balance_before) }
    it { should validate_presence_of(:balance_after) }
    it { should validate_numericality_of(:change_amount).only_integer }
  end
end
