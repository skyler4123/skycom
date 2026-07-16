require "rails_helper"

RSpec.describe OrderProcessingV1::ProcessPaymentService do
  describe ".call" do
    subject(:result) { described_class.call(order: order) }

    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:customer) { create(:customer, company: company) }
    let(:order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :pending) }

    it "creates an Invoice" do
      expect { result }.to change(Invoice, :count).by(1)
    end

    it "creates a Transaction" do
      expect { result }.to change(Transaction, :count).by(1)
    end

    it "sets Order workflow_status to paid" do
      result
      expect(order.reload.workflow_status).to eq("paid")
    end

    it "returns transaction_id" do
      expect(result[:transaction_id]).to be_present
    end

    context "when called twice on the same order" do
      before { described_class.call(order: order) }

      it "raises a validation error on duplicate invoice name" do
        expect { described_class.call(order: order) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
