# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingInvoice do
  subject(:invoice) { build(:billing_invoice, company: company, price_cents: 1000) }

  let(:company) { create(:company) }

  before do
    company.update_columns(promo_balance_cents: promo_balance,
                           main_balance_cents: 0,
                           lifecycle_status: 0) # active
    company.reload
  end

  describe "after_create_commit" do
    context "when wallet covers the invoice" do
      let(:promo_balance) { 2000 }

      it "pays the invoice automatically" do
        invoice.save!
        expect(invoice.reload.payment_status).to eq("paid")
      end

      it "deducts from promo balance" do
        invoice.save!
        expect(company.reload.promo_balance_cents).to eq(1000)
      end
    end

    context "when wallet is insufficient" do
      let(:promo_balance) { 300 }

      it "marks invoice as overdue", :aggregate_failures do
        invoice.save!
        expect(invoice.reload.payment_status).to eq("overdue")
        expect(company.reload.lifecycle_status).to eq("past_due")
      end
    end

    context "when wallet is empty" do
      let(:promo_balance) { 0 }

      it "leaves invoice unpaid" do
        invoice.save!
        expect(invoice.reload.payment_status).to eq("unpaid")
      end
    end
  end
end
