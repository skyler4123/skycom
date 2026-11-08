# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::StoreManagerController", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company, name: "Downtown Flagship") }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch, name: "WH-01 Central") }
  let!(:operation) { Seed::OperationService.create(company: company, operation_type: :store_manager) }
  let(:appointment) { operation.branch_operation_appointments.find_by!(branch: branch) }
  let(:customer) { Seed::CustomerService.create(company: company, branch: branch, name: "Marcus Vance") }
  let(:product) { create(:product, company: company, name: "MX Master 3S Graphite") }

  before do
    get sign_in_for_test_path(email: owner.email)
  end

  def create_order(workflow_status:, business_type:)
    order = Seed::OrderService.create(
      company: company,
      branch: branch,
      customer: customer,
      name: "Store order #{SecureRandom.hex(4)}",
      workflow_status: workflow_status,
      business_type: business_type
    )
    Seed::OrderProductAppointmentService.create(
      company: company,
      order: order,
      product: product,
      quantity: 2,
      unit_price: 50.0
    )
    order
  end

  def create_low_stock
    stock = Seed::StockService.create(
      company: company,
      warehouse: warehouse,
      branch: branch,
      product_id: product.id,
      name: "MX Master 3S Graphite",
      code: "LOGI-MX3S-GRP",
      quantity: 2,
      pending: 0,
      discarded_at: nil
    )
    stock.update!(discarded_at: nil)
    stock
  end

  describe "GET #show" do
    it "returns the live store manager payload" do
      paid_order = create_order(workflow_status: :paid, business_type: :in_store)
      pending_order = create_order(workflow_status: :pending, business_type: :online)
      create_low_stock

      get store_manager_company_operations_path(company, operation), params: { branch_id: branch.id }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["coming_soon"]).to be(false)
      expect(body.dig("store_manager", "branch", "name")).to eq("Downtown Flagship")
      expect(body.dig("store_manager", "kpis", "gross_sales_cents")).to eq(10_000)
      expect(body.dig("store_manager", "kpis", "orders_to_fulfill")).to eq(1)
      expect(body.dig("store_manager", "kpis", "shelf_alerts")).to eq(1)
      expect(body.dig("store_manager", "orders").map { |order| order["id"] }).to contain_exactly(paid_order.id, pending_order.id)
      expect(body.dig("store_manager", "replenishments").first["product_name"]).to eq("MX Master 3S Graphite")
      expect(body.dig("store_manager", "footfall", "connected")).to be(false)
    end

    it "rejects a branch appointment that is not active" do
      appointment.update!(workflow_status: :inactive)

      get store_manager_company_operations_path(company, operation), params: { branch_id: branch.id }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to contain_exactly("This operation is inactive.")
    end
  end
end
