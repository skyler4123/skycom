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

    it "defines status enum with pending as default" do
      expect(described_class.statuses).to match(
        hash_including("pending" => 0, "completed" => 1, "failed" => 2)
      )
      expect(tx.status).to eq("pending")
    end
  end

  describe "store_accessor" do
    it "reads and writes gateway_payload through metadata" do
      tx.save!
      tx.update!(gateway_payload: { qr_string: "test_qr", redirect_url: "http://example.com" })
      tx.reload
      expect(tx.gateway_payload).to eq("qr_string" => "test_qr", "redirect_url" => "http://example.com")
      expect(tx.metadata).to include("gateway_payload")
    end

    it "defaults gateway_payload to nil" do
      expect(tx.gateway_payload).to be_nil
    end
  end
end
