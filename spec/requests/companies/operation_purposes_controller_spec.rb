# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Company operations", type: :request do
  let(:company) { create(:company, business_type: :retail, country: :us) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company, name: "Main Branch") }
  let!(:other_branch) { create(:branch, company: company, name: "Other Branch") }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

  let!(:product_a) { create(:product, company: company, branch: branch, name: "Widget Alpha") }
  let!(:other_product) { create(:product, company: company, branch: other_branch, name: "Other Widget") }

  let!(:stock_a) do
    category = product_a.category
    Stock.create!(
      company: company,
      warehouse: warehouse,
      product: product_a,
      quantity: 10,
      pending: 0,
      category: category,
      property_mapping: category.default_property_mapping
    ).tap { |stock| stock.send(:sync_available_counter) }
  end

  let(:cash_pm) do
    PaymentMethod.create!(
      name: "Cash",
      code: "POS_CASH",
      business_type: :b2c,
      payment_mode: :cash,
      strategy: :cash
    )
  end
  let(:qr_pm) do
    PaymentMethod.create!(
      name: "Mock QR",
      code: "POS_QR",
      business_type: :b2c,
      payment_mode: :qr,
      strategy: :mock_qr_gateway
    )
  end
  let(:redirect_pm) do
    PaymentMethod.create!(
      name: "Redirect",
      code: "POS_REDIRECT",
      business_type: :b2c,
      payment_mode: :redirect,
      strategy: :mock_redirect_gateway
    )
  end

  before do
    [ cash_pm, qr_pm, redirect_pm ].each do |payment_method|
      CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: payment_method,
        name: "#{payment_method.name} company",
        code: "#{payment_method.code}_CO",
        business_type: :in_store,
        lifecycle_status: :active
      )
      BranchPaymentMethodAppointment.create!(
        company: company,
        branch: branch,
        payment_method: payment_method,
        name: "#{payment_method.name} branch",
        code: "#{payment_method.code}_BR",
        business_type: :in_store,
        lifecycle_status: :active
      )
    end
    Seed::OperationService.seed_defaults!(company: company)
    get sign_in_for_test_path(email: owner.email)
  end

  describe "GET #show for POS" do
    it "returns the operation, branch appointment, config, products and payment methods" do
      operation = company.operations.find_by!(operation_type: :pos)
      operation.update!(metadata: { "roles" => [], "layout" => { "columns" => 12 } })

      get pos_company_operations_path(company, operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("operation").fetch("operation_type")).to eq("pos")
      expect(body.fetch("appointment").fetch("branch")).to eq("id" => branch.id, "name" => "Main Branch")
      expect(body.fetch("config")).to eq("roles" => [], "layout" => { "columns" => 12 })
      expect(body.fetch("coming_soon")).to be(false)

      product_names = body.fetch("products").map { |product| product.fetch("name") }
      expect(product_names).to include("Widget Alpha")
      expect(product_names).not_to include("Other Widget")
      expect(body.fetch("products").first.fetch("stock_id")).to eq(stock_a.id)

      codes = body.fetch("payment_methods").map { |method| method.fetch("code") }
      expect(codes).to contain_exactly("POS_CASH", "POS_QR")
    end

    it "rejects an inactive appointment" do
      operation = company.operations.find_by!(operation_type: :pos)
      branch.branch_operation_appointments.find_by!(operation: operation).update!(workflow_status: :inactive)

      get pos_company_operations_path(company, operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("errors")).to include("This operation appointment is inactive.")
    end

    it "rejects an operation type that does not match the route" do
      booking = company.operations.find_by!(operation_type: :booking)

      get pos_company_operations_path(company, booking, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #show for a placeholder" do
    it "returns coming_soon with the operation and appointment" do
      operation = company.operations.find_by!(operation_type: :booking)

      get booking_company_operations_path(company, operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("coming_soon")).to be(true)
      expect(body.fetch("operation").fetch("operation_type")).to eq("booking")
      expect(body.fetch("appointment").fetch("kind")).to eq("branch")
    end

    it "returns coming_soon for warehouse-scoped inventory" do
      operation = company.operations.find_by!(operation_type: :inventory)

      get inventory_company_operations_path(company, operation, warehouse_id: warehouse.id), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("coming_soon")).to be(true)
    end
  end
end
