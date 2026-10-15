# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CustomerProfilesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "customer_profiles" }
    let(:index_class) { CustomerProfile }
    let(:json_key) { "customer_profiles" }
    let(:base_json_path) { "/companies/#{company.id}/customer_profiles.json" }
    let(:record) do
      lambda do |company:, category:, **attrs|
        customer = Customer.find_by(company: company) || create(:customer, company: company)
        Seed::CustomerProfileService.create(company: company, customer: customer, category: category, **attrs)
      end
    end
  end
end

RSpec.describe "Companies::CustomerProfilesController CRUD", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles") }
  let(:customer) { create(:customer, company: company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET index" do
    let!(:profile) { Seed::CustomerProfileService.create(company: company, customer: customer, category: category, name: "Profile 1") }

    it "returns profiles" do
      get "/companies/#{company.id}/customer_profiles.json", params: { category_id: category.id }
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["customer_profiles"].map { |c| c["id"] }
      expect(ids).to include(profile.id)
    end

    it "filters by customer_id" do
      other = create(:customer, company: company)
      Seed::CustomerProfileService.create(company: company, customer: other, category: category, name: "Profile X")
      get "/companies/#{company.id}/customer_profiles.json", params: { customer_id: customer.id }
      names = JSON.parse(response.body)["customer_profiles"].map { |c| c["name"] }
      expect(names).to include("Profile 1")
      expect(names).not_to include("Profile X")
    end
  end

  describe "POST create" do
    it "creates and redirects on success" do
      expect {
        post "/companies/#{company.id}/customer_profiles",
          params: { customer_profile: { name: "Profile 1", customer_id: customer.id, category_id: category.id, business_type: "general" } }
      }.to change(CustomerProfile, :count).by(1)
    end

    it "redirects with alert on failure and creates nothing" do
      expect {
        post "/companies/#{company.id}/customer_profiles",
          params: { customer_profile: { name: "", customer_id: customer.id, category_id: category.id } }
      }.not_to change(CustomerProfile, :count)
      expect(response).to have_http_status(:found)
    end
  end

  describe "DELETE destroy" do
    let(:destroy_customer) { create(:customer, company: company) }
    let!(:destroy_record) { Seed::CustomerProfileService.create(company: company, customer: destroy_customer, category: category, name: "Doomed #{SecureRandom.hex(4)}") }

    it "discards the record" do
      delete "/companies/#{company.id}/customer_profiles/#{destroy_record.id}.json"
      expect(response).to have_http_status(:ok)
      expect(destroy_record.reload.discarded?).to be_truthy
    end

    it "returns not_found for missing id" do
      delete "/companies/#{company.id}/customer_profiles/nonexistent-id.json"
      expect(response).to have_http_status(:not_found)
    end
  end
end
