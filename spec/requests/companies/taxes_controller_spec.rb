# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::TaxesController", type: :request do
  let(:company) { create(:company) }
  let(:from) { "2026-01-01" }
  let(:to) { "2026-01-31" }
  let(:config) { TaxConfig.for_company!(company) }

  before { get sign_in_for_test_path(email: company.user.email) }

  def at(value)
    Time.zone.parse(value)
  end

  def create_invoice(created_at:, updated_at: created_at, branch: nil, payment_status: :unpaid, company: nil)
    company ||= self.company
    customer = create(:customer, company: company)
    order = create(:order, company: company, branch: branch, customer: customer)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "invoices")

    create(:invoice, company: company, category: category, order: order, discarded_at: nil).tap do |invoice|
      invoice.update_columns(
        created_at: created_at,
        updated_at: updated_at,
        payment_status: Invoice.payment_statuses.fetch(payment_status.to_s)
      )
    end
  end

  def create_purchase(created_at:, updated_at: created_at, branch: nil, workflow_status: :draft, company: nil)
    company ||= self.company
    branch ||= create(:branch, company: company)
    warehouse = create(:warehouse, company: company, branch: branch)

    create(:purchase, company: company, branch: branch, warehouse: warehouse, discarded_at: nil).tap do |purchase|
      purchase.update_columns(
        created_at: created_at,
        updated_at: updated_at,
        workflow_status: Purchase.workflow_statuses.fetch(workflow_status.to_s)
      )
    end
  end

  def create_stock_export(created_at:, updated_at: created_at, branch: nil, business_type: :sale, company: nil)
    company ||= self.company
    branch ||= create(:branch, company: company)
    warehouse = create(:warehouse, company: company, branch: branch)
    product = create(:product, company: company)

    create(:stock_export, company: company, branch: branch, warehouse: warehouse, product: product, discarded_at: nil).tap do |stock_export|
      stock_export.update_columns(
        created_at: created_at,
        updated_at: updated_at,
        business_type: StockExport.business_types.fetch(business_type.to_s)
      )
    end
  end

  def fetch_invoices(**params)
    get company_tax_invoices_path(company, format: :json), params: { from: from, to: to }.merge(params)
  end

  def fetch_purchases(**params)
    get company_tax_purchases_path(company, format: :json), params: { from: from, to: to }.merge(params)
  end

  def fetch_stock_exports(**params)
    get company_tax_stock_exports_path(company, format: :json), params: { from: from, to: to }.merge(params)
  end

  def fetch_summary(**params)
    get company_tax_summary_path(company, format: :json), params: { from: from, to: to }.merge(params)
  end

  describe "GET /companies/:company_id/tax/invoices" do
    it "returns invoices inside the period for the created_at basis" do
      included = create_invoice(created_at: at("2026-01-15 12:00"))
      create_invoice(created_at: at("2025-12-15 12:00"))

      fetch_invoices

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["invoices"].map { |row| row["code"] }).to contain_exactly(included.code)
      expect(body["pagination"]).to be_present
    end

    it "uses updated_at when the config selects it" do
      config.update!(date_basis: "updated_at")
      included = create_invoice(created_at: at("2025-12-15 12:00"), updated_at: at("2026-01-15 12:00"))
      create_invoice(created_at: at("2026-01-15 12:00"), updated_at: at("2025-12-15 12:00"))

      fetch_invoices

      expect(response.parsed_body["invoices"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "uses due_date when the config selects it" do
      config.update!(date_basis: "due_date")
      included = create_invoice(created_at: at("2025-12-15 12:00"))
      included.update_columns(due_date: at("2026-01-20 12:00"))
      excluded = create_invoice(created_at: at("2026-01-15 12:00"))
      excluded.update_columns(due_date: at("2025-12-20 12:00"))

      fetch_invoices

      expect(response.parsed_body["invoices"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "excludes configured invoice statuses" do
      config.update!(excluded_invoice_statuses: [ "paid" ])
      included = create_invoice(created_at: at("2026-01-15 12:00"), payment_status: :unpaid)
      create_invoice(created_at: at("2026-01-15 12:00"), payment_status: :paid)

      fetch_invoices

      expect(response.parsed_body["invoices"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "limits invoices to the configured branches" do
      branch = create(:branch, company: company)
      other_branch = create(:branch, company: company)
      config.update!(branch_ids: [ branch.id ])
      included = create_invoice(created_at: at("2026-01-15 12:00"), branch: branch)
      create_invoice(created_at: at("2026-01-15 12:00"), branch: other_branch)

      fetch_invoices

      expect(response.parsed_body["invoices"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "returns no invoices when the source is disabled" do
      config.update!(include_invoices: false)
      create_invoice(created_at: at("2026-01-15 12:00"))

      fetch_invoices

      expect(response.parsed_body["invoices"]).to eq([])
    end

    it "falls back to created_at for an unknown date basis" do
      config.update!(date_basis: "created_at) OR 1=1 --")
      included = create_invoice(created_at: at("2026-01-15 12:00"))
      create_invoice(created_at: at("2025-12-15 12:00"))

      fetch_invoices

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["invoices"].map { |row| row["code"] }).to contain_exactly(included.code)
    end
  end

  describe "GET /companies/:company_id/tax/purchases" do
    it "uses updated_at when the config selects it" do
      config.update!(date_basis: "updated_at")
      included = create_purchase(created_at: at("2025-12-15 12:00"), updated_at: at("2026-01-15 12:00"))
      create_purchase(created_at: at("2026-01-15 12:00"), updated_at: at("2025-12-15 12:00"))

      fetch_purchases

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["purchases"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "excludes configured purchase statuses" do
      config.update!(excluded_purchase_statuses: [ "cancelled" ])
      included = create_purchase(created_at: at("2026-01-15 12:00"), workflow_status: :draft)
      create_purchase(created_at: at("2026-01-15 12:00"), workflow_status: :cancelled)

      fetch_purchases

      expect(response.parsed_body["purchases"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "limits purchases to the configured branches" do
      branch = create(:branch, company: company)
      other_branch = create(:branch, company: company)
      config.update!(branch_ids: [ branch.id ])
      included = create_purchase(created_at: at("2026-01-15 12:00"), branch: branch)
      create_purchase(created_at: at("2026-01-15 12:00"), branch: other_branch)

      fetch_purchases

      expect(response.parsed_body["purchases"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "returns no purchases when the source is disabled" do
      config.update!(include_purchases: false)
      create_purchase(created_at: at("2026-01-15 12:00"))

      fetch_purchases

      expect(response.parsed_body["purchases"]).to eq([])
    end
  end

  describe "GET /companies/:company_id/tax/stock_exports" do
    it "returns only the configured business types by default" do
      included = create_stock_export(created_at: at("2026-01-15 12:00"), business_type: :sale)
      create_stock_export(created_at: at("2026-01-15 12:00"), business_type: :transfer_out)

      fetch_stock_exports

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["stock_exports"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "uses updated_at when the config selects it" do
      config.update!(date_basis: "updated_at")
      included = create_stock_export(created_at: at("2025-12-15 12:00"), updated_at: at("2026-01-15 12:00"), business_type: :sale)
      create_stock_export(created_at: at("2026-01-15 12:00"), updated_at: at("2025-12-15 12:00"), business_type: :sale)

      fetch_stock_exports

      expect(response.parsed_body["stock_exports"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "limits stock exports to the configured branches" do
      branch = create(:branch, company: company)
      other_branch = create(:branch, company: company)
      config.update!(branch_ids: [ branch.id ])
      included = create_stock_export(created_at: at("2026-01-15 12:00"), branch: branch, business_type: :sale)
      create_stock_export(created_at: at("2026-01-15 12:00"), branch: other_branch, business_type: :sale)

      fetch_stock_exports

      expect(response.parsed_body["stock_exports"].map { |row| row["code"] }).to contain_exactly(included.code)
    end

    it "returns no stock exports when the source is disabled" do
      config.update!(include_stock_exports: false)
      create_stock_export(created_at: at("2026-01-15 12:00"), business_type: :sale)

      fetch_stock_exports

      expect(response.parsed_body["stock_exports"]).to eq([])
    end
  end

  describe "GET /companies/:company_id/tax/summary" do
    it "counts and totals only records inside the period" do
      invoice = create_invoice(created_at: at("2026-01-15 12:00"))
      create_invoice(created_at: at("2025-12-15 12:00"))
      create_purchase(created_at: at("2026-01-15 12:00"))
      create_purchase(created_at: at("2025-12-15 12:00"))
      create_stock_export(created_at: at("2026-01-15 12:00"), business_type: :sale)
      create_stock_export(created_at: at("2025-12-15 12:00"), business_type: :sale)

      fetch_summary

      expect(response).to have_http_status(:ok)
      summary = response.parsed_body["summary"]
      expect(summary.dig("invoices", "count")).to eq(1)
      expect(summary.dig("invoices", "total_cents")).to eq(invoice.price_cents)
      expect(summary.dig("purchases", "count")).to eq(1)
      expect(summary.dig("stock_exports", "count")).to eq(1)
    end

    it "returns zero totals when every source is disabled" do
      config.update!(include_invoices: false, include_purchases: false, include_stock_exports: false)
      create_invoice(created_at: at("2026-01-15 12:00"))
      create_purchase(created_at: at("2026-01-15 12:00"))
      create_stock_export(created_at: at("2026-01-15 12:00"), business_type: :sale)

      fetch_summary

      summary = response.parsed_body["summary"]
      expect(summary.dig("invoices", "count")).to eq(0)
      expect(summary.dig("invoices", "total_cents")).to eq(0)
      expect(summary.dig("purchases", "count")).to eq(0)
      expect(summary.dig("purchases", "total_amount")).to eq(0)
      expect(summary.dig("stock_exports", "count")).to eq(0)
      expect(summary.dig("stock_exports", "total_quantity")).to eq(0)
    end
  end

  describe "period and tenant boundaries" do
    it "swaps a reversed from/to period" do
      invoice = create_invoice(created_at: at("2026-01-15 12:00"))

      fetch_invoices(from: "2026-01-31", to: "2026-01-01")

      expect(response.parsed_body["invoices"].map { |row| row["code"] }).to contain_exactly(invoice.code)
    end

    it "never leaks records from another company" do
      other_company = create(:company)
      create_invoice(company: other_company, created_at: at("2026-01-15 12:00"))
      create_purchase(company: other_company, created_at: at("2026-01-15 12:00"))
      create_stock_export(company: other_company, created_at: at("2026-01-15 12:00"), business_type: :sale)

      fetch_invoices
      expect(response.parsed_body["invoices"]).to eq([])

      fetch_purchases
      expect(response.parsed_body["purchases"]).to eq([])

      fetch_stock_exports
      expect(response.parsed_body["stock_exports"]).to eq([])
    end
  end
end
