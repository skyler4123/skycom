# spec/models/transaction_spec.rb
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:invoice) }
    it { should belong_to(:payment_method).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:currency) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:payment_status) }
  end

  describe "status enum" do
    it { should define_enum_for(:status).with_values(pending: 0, completed: 1, failed: 2) }
  end

  describe "gateway payload accessor" do
    it "stores and reads gateway_payload through metadata" do
      txn = described_class.new(metadata: {})
      txn.gateway_payload = { "qr_string" => "ABC" }
      expect(txn.gateway_payload).to eq({ "qr_string" => "ABC" })
    end
  end

  describe "invoice payment_status derivation" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:customer) { create(:customer, company: company) }
    let(:order_record) { create(:order, company: company, branch: branch, customer: customer) }
    let(:invoice) do
      create(:invoice, order: order_record, price_cents: 1000,
        name: "Txn Spec #{SecureRandom.hex(4)}", code: "TXNSPEC-#{SecureRandom.hex(4)}")
    end

    def build_txn(status:)
      described_class.create!(
        company: company, invoice: invoice, price_cents: 1000, currency: :usd,
        status: status, business_type: :standard_payment,
        gateway_reference: "POS_#{SecureRandom.hex(8)}"
      )
    end

    it "does not mark the invoice paid while pending" do
      build_txn(status: :pending)
      expect(invoice.reload.payment_status).to eq("unpaid")
    end

    it "marks the invoice paid when completed" do
      build_txn(status: :completed)
      expect(invoice.reload.payment_status).to eq("paid")
    end

    it "re-derives to unpaid when a completed transaction is destroyed" do
      txn = build_txn(status: :completed)
      expect(invoice.reload.payment_status).to eq("paid")

      txn.destroy!
      expect(invoice.reload.payment_status).to eq("unpaid")
    end
  end

  it_behaves_like "property_mapping concern", Transaction
end
