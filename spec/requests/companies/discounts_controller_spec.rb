# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::DiscountsController", type: :request do
  let(:company) { create(:company) }
  let(:group) do
    Seed::DiscountGroupService.create(company: company, name: "Summer", prefix: "SUM26",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end
  let!(:discount) { Seed::DiscountService.create(company: company, discount_group: group, code: "SUM26-GET001") }
  let!(:used_discount) { Seed::DiscountService.create(company: company, discount_group: group, code: "SUM26-GET002") }

  before do
    customer = create(:customer, company: company)
    order = Seed::OrderService.create(company: company, customer: customer, currency: :usd)
    used_discount.reserve!(order: order, employee: create(:employee, company: company), amount_cents: 1_000)
    used_discount.consume!(invoice: create(:invoice, company: company, order: order, price_cents: 9_000))
    get sign_in_for_test_path(email: company.user.email)
  end

  describe "GET #index" do
    it "returns the company's codes with group info" do
      get company_discounts_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["discounts"].size).to eq(2)
      expect(body["discounts"].first["discount_group"]["name"]).to eq("Summer")
      expect(body).to have_key("pagination")
    end

    it "filters by status" do
      get company_discounts_path(company), params: { status: "used" }, as: :json

      codes = JSON.parse(response.body)["discounts"].map { |d| d["code"] }
      expect(codes).to eq([ "SUM26-GET002" ])
    end

    it "filters by group" do
      other = Seed::DiscountGroupService.create(company: company, name: "Other", prefix: "OTH",
        discount_type: :fixed_amount, amount_cents: 100)
      Seed::DiscountService.create(company: company, discount_group: other, code: "OTHER1")

      get company_discounts_path(company), params: { discount_group_id: other.id }, as: :json

      codes = JSON.parse(response.body)["discounts"].map { |d| d["code"] }
      expect(codes).to eq([ "OTHER1" ])
    end

    it "scopes to the current company" do
      foreign_company = create(:company)
      foreign_group = Seed::DiscountGroupService.create(company: foreign_company, name: "F", prefix: "F",
        discount_type: :fixed_amount, amount_cents: 100)
      foreign = Seed::DiscountService.create(company: foreign_company, discount_group: foreign_group, code: "FOREIGN1")

      get company_discounts_path(company), as: :json

      codes = JSON.parse(response.body)["discounts"].map { |d| d["code"] }
      expect(codes).not_to include("FOREIGN1")
      expect(foreign).to be_present
    end
  end

  describe "GET #show" do
    it "returns a single code with its bindings" do
      get company_discount_path(company, discount), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["discount"]["code"]).to eq("SUM26-GET001")
      expect(body["discount"]["status"]).to eq("unused")
      expect(body["discount"]["discount_group"]["prefix"]).to eq("SUM26")
    end

    it "returns 404 for a foreign company's code" do
      foreign_group = Seed::DiscountGroupService.create(company: create(:company), name: "FG", prefix: "FG",
        discount_type: :fixed_amount, amount_cents: 100)
      foreign = Seed::DiscountService.create(company: foreign_group.company, discount_group: foreign_group, code: "FOREIGN2")

      get company_discount_path(company, foreign), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
