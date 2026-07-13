# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingTransaction do
  subject(:tx) { build(:billing_transaction, company: company) }

  let(:company) { create(:company) }

  describe "associations" do
    it "belongs to company" do
      tx.save!
      expect(tx.company).to eq(company)
    end

    it "belongs to billing_invoice" do
      tx.save!
      expect(tx.billing_invoice).to be_present
    end
  end

  describe "validations" do
    it "requires billing_invoice" do
      tx.billing_invoice = nil
      expect(tx).not_to be_valid
      expect(tx.errors[:billing_invoice]).to be_present
    end

    it "validates amount_cents is >= 0" do
      tx.amount_cents = -1
      expect(tx).not_to be_valid
      expect(tx.errors[:amount_cents]).to be_present
    end

    it "allows amount_cents of 0" do
      tx.amount_cents = 0
      expect(tx).to be_valid
    end
  end

  describe "enums" do
    it "defines transaction_type enum" do
      expect(described_class.transaction_types).to match(
        hash_including("top_up" => 0, "deduction" => 1, "refund" => 2, "promo_credit" => 3)
      )
    end
  end
end
