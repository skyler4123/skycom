# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::Pos", type: :request do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:branch) { create(:branch, company: company) }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :pos) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Main warehouse", business_type: :main) }
  let(:product) { create(:product, company: company, branch: branch, name: "Widget", price_cents: 5_000) }
  let(:service) do
    Seed::ServiceService.create(company: company, branch: branch, name: "Assembly").tap do |record|
      record.update!(price_cents: 2_500)
    end
  end
  let(:default_tax) { create(:tax_code, company: company, name: "Sales tax", rate_bp: 800) }
  let!(:stock) do
    category = product.category
    Stock.create!(
      company: company, warehouse: warehouse, product: product,
      quantity: 12, pending: 0, category: category,
      property_mapping: category.default_property_mapping
    ).tap { |record| record.send(:sync_available_counter) }
  end

  let(:cash_pm) do
    PaymentMethod.create!(name: "Cash", code: "POS_REQ_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
  end

  before do
    ActiveStorage::Current.url_options = { host: "localhost", port: 3000 }
    service.update!(branch: branch, price_cents: 2_500)
    CompanyPaymentMethodAppointment.create!(company: company, payment_method: cash_pm,
      name: "Company cash", code: "POS_REQ_CO_CASH", business_type: :in_store, lifecycle_status: :active)
    BranchPaymentMethodAppointment.create!(company: company, branch: branch, payment_method: cash_pm,
      name: "Branch cash", code: "POS_REQ_BR_CASH", business_type: :in_store, lifecycle_status: :active)
    TaxConfig.for_company!(company).update!(default_tax_code_id: default_tax.id)
    get sign_in_for_test_path(email: company_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def show_payload
    get "/companies/#{company.id}/operations/pos/#{operation_record.id}.json",
      params: { branch_id: branch.id }
    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  it "returns company currency, per-item tax, catalog counts, and cent prices" do
    body = show_payload

    expect(body["currency"]).to eq("usd")
    expect(body).not_to have_key("tax")
    expect(body.dig("catalog", "limit")).to eq(POS_CATALOG_LIMIT)
    expect(body.dig("catalog", "products_total")).to eq(1)
    expect(body.dig("catalog", "services_total")).to eq(1)

    row = body["products"].find { |item| item["id"] == product.id }
    expect(row["price_cents"]).to eq(5_000)
    expect(row["price_set"]).to be(true)
    expect(row["stock_quantity"]).to eq(12)
    expect(row["stock_warehouse_name"]).to eq("Main warehouse")
    expect(row.dig("tax", "rate_bp")).to eq(800)
    expect(row.dig("tax", "name")).to eq("Sales tax")

    service_row = body["services"].find { |item| item["id"] == service.id }
    expect(service_row["price_cents"]).to eq(2_500)
    expect(service_row["price_set"]).to be(true)
    expect(service_row["stock_quantity"]).to be_nil
  end

  it "does not leak another company's catalog" do
    other = Seed::CompanyService.new(user: create(:user, :company_owner), country: :us, business_type: :retail).tap(&:save!)
    other_branch = create(:branch, company: other)
    create(:product, company: other, branch: other_branch, name: "Foreign widget", price_cents: 9_999)

    body = show_payload

    expect(body["products"].map { |row| row["name"] }).not_to include("Foreign widget")
  end

  describe "terminal lock" do
    it "locks and unlocks with the signed-in user's password" do
      post "/companies/#{company.id}/operations/pos/#{operation_record.id}/lock",
        params: { branch_id: branch.id }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["locked"]).to be(true)
      expect(show_payload["locked"]).to be(true)

      post "/companies/#{company.id}/operations/pos/#{operation_record.id}/unlock",
        params: { branch_id: branch.id, password: "WrongPassword@1234" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to include("Incorrect password")
      expect(show_payload["locked"]).to be(true)

      post "/companies/#{company.id}/operations/pos/#{operation_record.id}/unlock",
        params: { branch_id: branch.id, password: "Password@1234" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["locked"]).to be(false)
      expect(show_payload["locked"]).to be(false)
    end
  end
end
