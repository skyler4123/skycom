# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::DiscountGroupsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: "owner") }
  let(:employee) { create(:employee, company: company) }
  let!(:group) do
    Seed::DiscountGroupService.create(company: company, name: "Summer", prefix: "SUM26",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: company.user.email) }

  describe "GET #index" do
    it "returns the company's groups with a pagination block" do
      group
      get company_discount_groups_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["discount_groups"].size).to eq(1)
      expect(body["discount_groups"].first["name"]).to eq("Summer")
      expect(body).to have_key("pagination")
    end

    it "scopes to the current company" do
      other_group = Seed::DiscountGroupService.create(company: create(:company), name: "Foreign", prefix: "FOR",
        discount_type: :fixed_amount, amount_cents: 100)

      get company_discount_groups_path(company), as: :json

      names = JSON.parse(response.body)["discount_groups"].map { |g| g["name"] }
      expect(names).to include("Summer")
      expect(names).not_to include("Foreign")
      expect(other_group).to be_present
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        discount_group: {
          name: "Winter Sale", prefix: "WIN26", discount_type: "fixed_amount",
          amount_cents: 500, campaign_status: "active"
        }
      }
    end

    it "creates the group as the owner" do
      expect {
        post company_discount_groups_path(company), params: valid_params
      }.to change(DiscountGroup, :count).by(1)

      follow_redirect!
      expect(response.body).to include("Discount group created successfully")
    end

    it "ignores a posted current_spent_cents" do
      post company_discount_groups_path(company), params: valid_params.merge(
        discount_group: valid_params[:discount_group].merge(current_spent_cents: 99_999)
      )

      expect(DiscountGroup.find_by(name: "Winter Sale").current_spent_cents).to eq(0)
    end

    it "redirects back with an alert for invalid params" do
      post company_discount_groups_path(company), params: {
        discount_group: { name: "", prefix: "X", discount_type: "percentage" }
      }

      expect(response).to redirect_to(new_company_discount_group_path(company))
      follow_redirect!
      expect(flash[:alert]).to be_present
    end

    it "returns 403 for an employee without create permission" do
      get sign_in_for_test_path(email: employee.user.email)

      post company_discount_groups_path(company), params: valid_params, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns the created group as JSON for the rich create page" do
      post company_discount_groups_path(company), params: valid_params, as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["discount_group"]["name"]).to eq("Winter Sale")
      expect(body["discount_group"]["prefix"]).to eq("WIN26")
    end

    it "returns 422 errors JSON for invalid params" do
      post company_discount_groups_path(company),
        params: { discount_group: { name: "", prefix: "X", discount_type: "percentage" } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end

  describe "POST #generate_codes" do
    it "generates codes for the group" do
      group

      expect {
        post generate_codes_company_discount_group_path(company, group), params: { quantity: 5 }
      }.to change(Discount, :count).by(5)

      body = JSON.parse(response.body)
      expect(body["message"]).to eq("5 discount codes generated")
      expect(body["group"]["generated_codes_count"]).to eq(5)
      codes = group.discounts.pluck(:code)
      expect(codes).to all(match(/\ASUM26-[A-Z0-9]{8}\z/))
    end

    it "returns 422 with errors for an invalid quantity" do
      post generate_codes_company_discount_group_path(company, group), params: { quantity: 0 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to eq([ "Quantity must be between 1 and 1000" ])
    end

    it "returns 403 for an employee without update permission" do
      get sign_in_for_test_path(email: employee.user.email)

      post generate_codes_company_discount_group_path(company, group), params: { quantity: 5 }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH #update" do
    it "updates the group and persists the campaign status" do
      patch company_discount_group_path(company, group),
        params: { discount_group: { name: "Renamed", campaign_status: "paused" } }

      follow_redirect!
      expect(group.reload.name).to eq("Renamed")
      expect(group.reload).to be_campaign_status_paused
    end

    it "returns the updated group as JSON (fetch-driven lifecycle toggle)" do
      patch company_discount_group_path(company, group),
        params: { discount_group: { campaign_status: "paused" } }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["discount_group"]["campaign_status"]).to eq("paused")
      expect(group.reload).to be_campaign_status_paused
    end
  end

  describe "DELETE #destroy" do
    it "removes the group and its codes" do
      group
      Discounts::BatchGenerator.call(discount_group: group, quantity: 3)

      expect {
        delete company_discount_group_path(company, group)
      }.to change(DiscountGroup, :count).by(-1)
        .and change(Discount, :count).by(-3)
    end
  end
end
