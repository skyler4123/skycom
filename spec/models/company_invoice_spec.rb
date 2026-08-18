# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyInvoice, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:company_order).optional }
    it { should have_many(:company_transactions).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:payment_status).with_values(unpaid: 0, paid: 1, overdue: 2, refunded: 3) }
    it { should define_enum_for(:currency).with_values(usd: 840, vnd: 704).with_prefix(:currency) }
  end

  describe "validations" do
    it { should validate_presence_of(:invoice_number).on(:update) }
    it { expect(build(:company_invoice)).to validate_uniqueness_of(:invoice_number) }
    it { should validate_presence_of(:money_amount_cents) }
    it { should validate_presence_of(:credit_amount) }
  end

  describe "invoice number generation" do
    it "auto-generates an INV-YYYYMM-HEX number on create" do
      invoice = create(:company_invoice, invoice_number: nil)
      expect(invoice.invoice_number).to match(/\AINV-\d{6}-[0-9A-F]{6}\z/)
    end
  end

  describe "order completion" do
    it "completes the linked order when payment_status transitions to paid" do
      company = create(:company, country: :us)
      order = create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000)
      invoice = create(:company_invoice, company: company, company_order: order, money_amount_cents: 500, credit_amount: 500_000)

      expect { invoice.update!(payment_status: :paid) }
        .to change { order.reload.workflow_status }.from("pending").to("completed")
      expect(company.company_wallet.reload.credit_balance).to eq(500_000)
    end

    it "does nothing for invoices without an order" do
      invoice = create(:company_invoice, company_order: nil)
      expect { invoice.update!(payment_status: :paid) }.not_to raise_error
    end

    it "does not re-complete when payment_status does not change" do
      company = create(:company, country: :us)
      order = create(:company_order, company: company, money_amount_cents: 500, credit_amount: 500_000)
      invoice = create(:company_invoice, company: company, company_order: order, money_amount_cents: 500, credit_amount: 500_000)
      invoice.update!(payment_status: :paid)
      order.reload

      expect {
        invoice.update!(invoice_number: "INV-REPROCESSED")
      }.not_to change(CompanyWalletLog, :count)
      expect(order.reload.workflow_status).to eq("completed")
    end
  end

  describe "scopes" do
    it "scopes unpaid and paid invoices" do
      create(:company_invoice, payment_status: :paid)
      create(:company_invoice, payment_status: :unpaid)

      expect(described_class.unpaid.count).to eq(1)
      expect(described_class.paid.count).to eq(1)
    end
  end
end
