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

    it "creates a Payment" do
      expect { result }.to change(Payment, :count).by(1)
    end

    it "sets Order workflow_status to paid" do
      result
      expect(order.reload.workflow_status).to eq("paid")
    end

    it "returns payment_id" do
      expect(result[:payment_id]).to be_present
    end
  end
end
