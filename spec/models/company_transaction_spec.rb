# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyTransaction, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:company_invoice) }
    it { should belong_to(:billing_payment_method) }
  end

  describe "enums" do
    it { should define_enum_for(:transaction_type).with_values(payment: 0, refund: 1) }
    it { should define_enum_for(:status).with_values(pending: 0, completed: 1, failed: 2) }
    it { should define_enum_for(:currency).with_values(usd: 840, vnd: 704).with_prefix(:currency) }
  end

  describe "validations" do
    it { should validate_presence_of(:money_amount_cents) }
    it { should validate_numericality_of(:money_amount_cents).only_integer.is_greater_than(0) }
    it { expect(build(:company_transaction)).to validate_uniqueness_of(:gateway_reference).allow_nil }
  end

  describe "invoice payment_status derivation (the chain)" do
    let(:company) { create(:company, country: :us) }
    let(:order) { create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000) }
    let(:invoice) { create(:company_invoice, company: company, company_order: order, money_amount_cents: 500, credit_amount: 500_000) }
    let(:payment_method) { create(:billing_payment_method, :mock_qr) }

    it "derives invoice paid and completes the chain when a completed payment covers the invoice" do
      wallet = company.wallet

      expect {
        create(:company_transaction, company: company, company_invoice: invoice,
          billing_payment_method: payment_method, money_amount_cents: 500, status: :completed)
      }.to change { invoice.reload.payment_status }.from("unpaid").to("paid")
        .and change { order.reload.workflow_status }.from("pending").to("completed")
        .and change { wallet.reload.credit_balance }.by(500_000)
        .and change(CompanyWalletLog, :count).by(1)
    end

    it "leaves the invoice unpaid when the payment does not cover the full amount" do
      create(:company_transaction, company: company, company_invoice: invoice,
        billing_payment_method: payment_method, money_amount_cents: 200, status: :completed)

      expect(invoice.reload.payment_status).to eq("unpaid")
      expect(order.reload.workflow_status).to eq("pending")
    end

    it "does not derive paid from pending or failed transactions" do
      create(:company_transaction, company: company, company_invoice: invoice,
        billing_payment_method: payment_method, money_amount_cents: 500, status: :pending)
      create(:company_transaction, company: company, company_invoice: invoice,
        billing_payment_method: payment_method, money_amount_cents: 500, status: :failed)

      expect(invoice.reload.payment_status).to eq("unpaid")
    end

    it "reverts the invoice to unpaid when its only payment is destroyed" do
      txn = create(:company_transaction, company: company, company_invoice: invoice,
        billing_payment_method: payment_method, money_amount_cents: 500, status: :completed)
      expect(invoice.reload.payment_status).to eq("paid")

      expect { txn.destroy! }.to change { invoice.reload.payment_status }.from("paid").to("unpaid")
    end

    it "does not double-credit the wallet when a second payment is added to an already-paid invoice" do
      create(:company_transaction, company: company, company_invoice: invoice,
        billing_payment_method: payment_method, money_amount_cents: 500, status: :completed)
      expect(company.wallet.credit_balance).to eq(500_000)

      create(:company_transaction, company: company, company_invoice: invoice,
        billing_payment_method: payment_method, money_amount_cents: 500, status: :completed)

      expect(invoice.reload.payment_status).to eq("paid")
      expect(order.reload.workflow_status).to eq("completed")
      expect(company.wallet.reload.credit_balance).to eq(500_000)
      expect(CompanyWalletLog.count).to eq(1)
    end
  end
end
