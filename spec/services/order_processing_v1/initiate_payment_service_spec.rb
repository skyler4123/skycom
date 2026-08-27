# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::InitiatePaymentService do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :pending) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    cat = product.category
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 0, category: cat, property_mapping: cat.default_property_mapping)
      .tap { |s| s.send(:sync_available_counter) }
  end
  let!(:line_item) do
    OrderAppointment.create!(order: order, appoint_to: product, company: company,
      quantity: 2, unit_price: 50.0, total_price: 100.0)
  end

  let(:cash_pm) do
    PaymentMethod.create!(name: "Cash IPS", code: "IPS_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
  end
  let(:qr_pm) do
    PaymentMethod.create!(name: "Mock QR IPS", code: "IPS_MQR", business_type: :b2c,
      payment_mode: :qr, strategy: :mock_qr_gateway)
  end

  let!(:cash_appts) do
    [
      PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: cash_pm,
        name: "Co cash", code: "CO_IPS_CASH", business_type: :in_store, lifecycle_status: :active),
      PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: cash_pm,
        name: "Br cash", code: "BR_IPS_CASH", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "1234567890", merchant_name: company.name, merchant_id: "T-AAAA")
    ]
  end
  let!(:qr_appts) do
    [
      PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: qr_pm,
        name: "Co qr", code: "CO_IPS_MQR", business_type: :in_store, lifecycle_status: :active),
      PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: qr_pm,
        name: "Br qr", code: "BR_IPS_MQR", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "0987654321", merchant_name: company.name, merchant_id: "T-BBBB")
    ]
  end

  describe "cash mode" do
    it "reserves stock, completes synchronously and returns a paid result" do
      result = described_class.call(order: order, appointment: cash_appts.last)

      aggregate_failures do
        expect(result.status).to eq("paid")
        expect(result.transaction_id).to be_present
        expect(order.reload.workflow_status).to eq("paid")

        txn = Transaction.find(result.transaction_id)
        expect(txn.status).to eq("completed")
        expect(txn.payment_method_id).to eq(cash_pm.id)
        expect(txn.invoice.reload.payment_status).to eq("paid")
        expect(stock.reload.pending).to eq(2)
      end
    end
  end

  describe "qr mode" do
    before do
      allow(Payments::MockQrGateway).to receive(:new).and_return(
        double(call: { success: true, gateway_reference: "MOCK_QR_1", gateway_payload: { "qr_string" => "QRDATA" } })
      )
    end

    it "creates a pending transaction and returns the qr_string" do
      result = described_class.call(order: order, appointment: qr_appts.last)

      aggregate_failures do
        expect(result.status).to eq("pending")
        expect(result.qr_string).to eq("QRDATA")
        expect(result.transaction_token).to start_with("POS_")

        txn = Transaction.find_by(gateway_reference: result.transaction_token)
        expect(txn.status).to eq("pending")
        expect(txn.payment_method_id).to eq(qr_pm.id)
        expect(txn.gateway_payload).to eq({ "qr_string" => "QRDATA" })
        expect(txn.invoice.reload.payment_status).to eq("unpaid")
        expect(order.reload.workflow_status).to eq("pending")
        expect(stock.reload.pending).to eq(2)
      end
    end

    it "passes merchant identity from the appointment to the gateway" do
      described_class.call(order: order, appointment: qr_appts.last)

      expect(Payments::MockQrGateway).to have_received(:new).with(
        hash_including(
          merchant_number: "0987654321",
          merchant_name: company.name,
          merchant_id: "T-BBBB",
          transaction_token: a_string_starting_with("POS_")
        )
      )
    end

    it "rolls back and releases stock when the gateway fails" do
      allow(Payments::MockQrGateway).to receive(:new).and_return(
        double(call: { success: false, error: "bank down" })
      )

      expect {
        described_class.call(order: order, appointment: qr_appts.last)
      }.to raise_error(OrderProcessingV1::InvalidPaymentMethodError, /bank down/)

      expect(Transaction.count).to eq(0)
      expect(Invoice.count).to eq(0)
      expect(stock.reload.pending).to eq(0)
      expect(stock.available_count).to eq(10)
    end
  end

  describe "validation" do
    it "rejects an inactive appointment" do
      cash_appts.last.update_columns(lifecycle_status: 3)

      expect {
        described_class.call(order: order, appointment: cash_appts.last.reload)
      }.to raise_error(OrderProcessingV1::InvalidPaymentMethodError)
    end

    it "rejects an appointment from another branch" do
      other_branch = create(:branch, company: company)
      other_appt = PaymentMethodAppointment.create!(appoint_to: other_branch, company: company,
        payment_method: cash_pm, name: "Other br cash", code: "OB_IPS_CASH",
        business_type: :in_store, lifecycle_status: :active)

      expect {
        described_class.call(order: order, appointment: other_appt)
      }.to raise_error(OrderProcessingV1::InvalidPaymentMethodError)
    end

    it "raises InsufficientStockError without creating records when stock is short" do
      stock.update_columns(quantity: 1)
      stock.send(:sync_available_counter)

      expect {
        described_class.call(order: order, appointment: cash_appts.last)
      }.to raise_error(OrderProcessingV1::InsufficientStockError)

      expect(Invoice.count).to eq(0)
      expect(Transaction.count).to eq(0)
    end
  end
end
