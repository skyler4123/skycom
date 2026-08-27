# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OrderProcessing::V1", type: :request do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner_user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    cat = product.category
    Stock.create!(
      company: company,
      warehouse: warehouse,
      product: product,
      quantity: 10,
      pending: 0,
      category: cat,
      property_mapping: cat.default_property_mapping
    )
  end
  let(:headers) { { "ACCEPT" => "application/json" } }

  before do
    stock.send(:sync_available_counter)
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "POST /companies/:id/order_processing/v1/checkout" do
    let(:checkout_params) do
      {
        branch_id: branch.id,
        items: [
          { stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 }
        ]
      }
    end

    it "returns 201 with order_id and total_price" do
      post "/companies/#{company.id}/order_processing/v1/checkout", params: checkout_params, headers: headers
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["order_id"]).to be_present
      expect(body["total_price"]).to eq(100.0)
    end

    context "with multiple items" do
      let(:product2) { create(:product, company: company) }
      let!(:stock2) do
        Stock.create!(company:, warehouse:, product: product2, quantity: 5, pending: 0,
          category: stock.category, property_mapping: stock.property_mapping)
          .tap { |s| s.send(:sync_available_counter) }
      end
      let(:checkout_params) do
        { branch_id: branch.id, items: [
          { stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 },
          { stock_id: stock2.id, product_id: product2.id, quantity: 1, unit_price: 25.00 }
        ] }
      end

      it "returns 201 with correct combined total_price" do
        post "/companies/#{company.id}/order_processing/v1/checkout", params: checkout_params, headers: headers
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["order_id"]).to be_present
        expect(body["total_price"]).to eq(125.0)
      end
    end

    context "with string quantity param" do
      let(:checkout_params) do
        { branch_id: branch.id, items: [ { stock_id: stock.id, product_id: product.id, quantity: "2", unit_price: 50.00 } ] }
      end

      it "returns 201 (handles .to_i conversion)" do
        post "/companies/#{company.id}/order_processing/v1/checkout", params: checkout_params, headers: headers
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["total_price"]).to eq(100.0)
      end
    end

    context "when stock insufficient" do
      let(:checkout_params) do
        { branch_id: branch.id, items: [ { stock_id: stock.id, product_id: product.id, quantity: 20, unit_price: 50.00 } ] }
      end

      it "returns 422" do
        post "/companies/#{company.id}/order_processing/v1/checkout", params: checkout_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["errors"]).to contain_exactly("Insufficient stock")
      end
    end

    context "when the Redis counter is missing" do
      before { Kredis.redis.del("stock:#{stock.id}:available") }

      it "returns 201 instead of crashing" do
        post "/companies/#{company.id}/order_processing/v1/checkout", params: checkout_params, headers: headers
        expect(response).to have_http_status(:created)
      end
    end
  end

  let(:cash_pm) do
    PaymentMethod.create!(name: "Cash Req", code: "REQ_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
  end
  let(:qr_pm) do
    PaymentMethod.create!(name: "Mock QR Req", code: "REQ_MQR", business_type: :b2c,
      payment_mode: :qr, strategy: :mock_qr_gateway)
  end
  let!(:cash_appts) do
    [
      PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: cash_pm,
        name: "Co cash", code: "RQ_CO_CASH", business_type: :in_store, lifecycle_status: :active),
      PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: cash_pm,
        name: "Br cash", code: "RQ_BR_CASH", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "1111111111", merchant_name: "Req Shop", merchant_id: "T-RQ01")
    ]
  end
  let!(:qr_appts) do
    [
      PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: qr_pm,
        name: "Co qr", code: "RQ_CO_MQR", business_type: :in_store, lifecycle_status: :active),
      PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: qr_pm,
        name: "Br qr", code: "RQ_BR_MQR", business_type: :in_store, lifecycle_status: :active,
        merchant_number: "2222222222", merchant_name: "Req Shop", merchant_id: "T-RQ02")
    ]
  end

  def checkout_order
    post "/companies/#{company.id}/order_processing/v1/checkout",
      params: { branch_id: branch.id, items: [ { stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 } ] },
      headers: headers
    JSON.parse(response.body)["order_id"]
  end

  describe "POST /companies/:id/order_processing/v1/pay" do
    context "with cash" do
      it "pays instantly and records the payment method" do
        order_id = checkout_order

        post "/companies/#{company.id}/order_processing/v1/pay",
          params: { order_id: order_id, payment_method_appointment_id: cash_appts.last.id }, headers: headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("paid")

        order = Order.find(order_id)
        expect(order.workflow_status).to eq("paid")
        txn = Transaction.joins(:invoice).find_by(invoice: { order_id: order_id })
        expect(txn.status).to eq("completed")
        expect(txn.payment_method_id).to eq(cash_pm.id)
      end

      it "transitions order to paid" do
        order_id = checkout_order

        expect {
          post "/companies/#{company.id}/order_processing/v1/pay",
            params: { order_id: order_id, payment_method_appointment_id: cash_appts.last.id }, headers: headers
        }.to change { Order.find(order_id).reload.workflow_status }.from("pending").to("paid")
      end
    end

    context "with mock qr" do
      before do
        allow(Payments::MockQrGateway).to receive(:new).and_return(
          double(call: { success: true, gateway_reference: "MOCK_QR_R1", gateway_payload: { "qr_string" => "REQQR" } })
        )
      end

      it "returns a pending payment with the qr_string" do
        order_id = checkout_order

        post "/companies/#{company.id}/order_processing/v1/pay",
          params: { order_id: order_id, payment_method_appointment_id: qr_appts.last.id }, headers: headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("pending")
        expect(body["qr_string"]).to eq("REQQR")
        expect(body["transaction_token"]).to start_with("POS_")

        expect(Order.find(order_id).workflow_status).to eq("pending")
        txn = Transaction.find_by(gateway_reference: body["transaction_token"])
        expect(txn.status).to eq("pending")
      end
    end

    it "rejects an appointment from another branch" do
      order_id = checkout_order
      other_branch = create(:branch, company: company)
      foreign = PaymentMethodAppointment.create!(appoint_to: other_branch, company: company,
        payment_method: cash_pm, name: "Foreign cash", code: "RQ_FB_CASH",
        business_type: :in_store, lifecycle_status: :active)

      post "/companies/#{company.id}/order_processing/v1/pay",
        params: { order_id: order_id, payment_method_appointment_id: foreign.id }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "rejects an unknown appointment with 404" do
      order_id = checkout_order

      post "/companies/#{company.id}/order_processing/v1/pay",
        params: { order_id: order_id, payment_method_appointment_id: "00000000-0000-0000-0000-000000000000" },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end

    context "with non-existent order_id" do
      it "returns 404" do
        post "/companies/#{company.id}/order_processing/v1/pay",
          params: { order_id: "nonexistent", payment_method_appointment_id: cash_appts.last.id }, headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /companies/:id/order_processing/v1/pay_cancel" do
    it "cancels a pending qr payment and releases stock" do
      allow(Payments::MockQrGateway).to receive(:new).and_return(
        double(call: { success: true, gateway_reference: "MOCK_QR_R2", gateway_payload: { "qr_string" => "CANCELQR" } })
      )
      order_id = checkout_order
      post "/companies/#{company.id}/order_processing/v1/pay",
        params: { order_id: order_id, payment_method_appointment_id: qr_appts.last.id }, headers: headers
      token = JSON.parse(response.body)["transaction_token"]
      expect(stock.reload.pending).to eq(2)

      post "/companies/#{company.id}/order_processing/v1/pay_cancel",
        params: { transaction_token: token }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("cancelled")
      expect(Transaction.find_by(gateway_reference: token).status).to eq("failed")
      expect(stock.reload.pending).to eq(0)
      expect(stock.available_count).to eq(10)
    end
  end

  describe "full checkout + pay flow" do
    let(:checkout_params) do
      { branch_id: branch.id, items: [ { stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 } ] }
    end

    it "decrements Redis counter and creates payment artifacts" do
      post "/companies/#{company.id}/order_processing/v1/checkout", params: checkout_params, headers: headers
      expect(response).to have_http_status(:created)
      order_id = JSON.parse(response.body)["order_id"]

      expect(stock.available_counter.value.to_i).to eq(10)

      post "/companies/#{company.id}/order_processing/v1/pay",
        params: { order_id: order_id, payment_method_appointment_id: cash_appts.last.id }, headers: headers
      expect(response).to have_http_status(:ok)

      expect(stock.reload.available_counter.value.to_i).to eq(8)

      order = Order.find(order_id)
      expect(order.workflow_status).to eq("paid")
      expect(Invoice.where(order_id: order.id)).to be_present
      expect(Transaction.joins(:invoice).where(invoice: { order_id: order.id })).to be_present
    end
  end
end
