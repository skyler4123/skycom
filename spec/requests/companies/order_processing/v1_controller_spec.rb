# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OrderProcessing::V1", type: :request do
  let(:company) { create(:company) }
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
      reorder: 0,
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
        Stock.create!(company:, warehouse:, product: product2, quantity: 5, reorder: 0,
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
        expect(body["error"]).to eq("Insufficient stock")
      end
    end
  end

  describe "POST /companies/:id/order_processing/v1/pay" do
    let(:customer) { create(:customer, company: company) }
    let!(:order) do
      Seed::OrderService.create(
        company: company,
        branch: branch,
        customer: customer,
        workflow_status: :pending
      )
    end
    let!(:order_appointment) do
      order.order_appointments.create!(
        company: company,
        appoint_to: product,
        quantity: 2,
        unit_price: 50,
        total_price: 100
      )
    end

    it "returns 200 with status paid" do
      post "/companies/#{company.id}/order_processing/v1/pay", params: { order_id: order.id }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("paid")
      expect(body["order_id"]).to eq(order.id)
      expect(body["payment_id"]).to be_present
    end

    it "transitions order to paid" do
      expect {
        post "/companies/#{company.id}/order_processing/v1/pay", params: { order_id: order.id }, headers: headers
      }.to change { order.reload.workflow_status }.from("pending").to("paid")
    end

    context "with non-existent order_id" do
      it "returns 404" do
        post "/companies/#{company.id}/order_processing/v1/pay", params: { order_id: "nonexistent" }, headers: headers
        expect(response).to have_http_status(:not_found)
      end
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

      post "/companies/#{company.id}/order_processing/v1/pay", params: { order_id: order_id }, headers: headers
      expect(response).to have_http_status(:ok)

      expect(stock.reload.available_counter.value.to_i).to eq(8)

      order = Order.find(order_id)
      expect(order.workflow_status).to eq("paid")
      expect(Invoice.where(order_id: order.id)).to be_present
      expect(Payment.joins(:invoice).where(invoice: { order_id: order.id })).to be_present
    end
  end
end
