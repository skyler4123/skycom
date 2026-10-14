# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CustomerSubprofilesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "customer_subprofiles" }
    let(:index_class) { CustomerSubprofile }
    let(:json_key) { "customer_subprofiles" }
    let(:base_json_path) { "/companies/#{company.id}/customer_subprofiles.json" }
    let(:record) do
      lambda do |company:, category:, **attrs|
        customer = Customer.find_by(company: company) || create(:customer, company: company)
        profile_category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles")
        profile = CustomerProfile.find_by(company: company, customer: customer) ||
          Seed::CustomerProfileService.create(company: company, customer: customer, category: profile_category, name: "Profile #{SecureRandom.hex(4)}")
        Seed::CustomerSubprofileService.create(company: company, customer: customer, customer_profile: profile, category: category, **attrs)
      end
    end
  end
end

RSpec.describe "Companies::CustomerSubprofilesController CRUD", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_subprofiles") }
  let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles") }
  let(:customer) { create(:customer, company: company) }
  let(:profile) { Seed::CustomerProfileService.create(company: company, customer: customer, category: profile_category, name: "Profile 1") }

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
    let!(:sub) { Seed::CustomerSubprofileService.create(company: company, customer: customer, customer_profile: profile, category: category, name: "Subprofile 11") }

    it "returns subprofiles" do
      get "/companies/#{company.id}/customer_subprofiles.json", params: { category_id: category.id }
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["customer_subprofiles"].map { |c| c["id"] }
      expect(ids).to include(sub.id)
    end
  end

  describe "POST create" do
    it "creates and redirects on success" do
      expect {
        post "/companies/#{company.id}/customer_subprofiles",
          params: { customer_subprofile: { name: "Subprofile 11", customer_id: customer.id, customer_profile_id: profile.id, category_id: category.id, business_type: "general" } }
      }.to change(CustomerSubprofile, :count).by(1)
    end

    it "fails when customer mismatches profile" do
      other = create(:customer, company: company)
      expect {
        post "/companies/#{company.id}/customer_subprofiles",
          params: { customer_subprofile: { name: "Bad", customer_id: other.id, customer_profile_id: profile.id, category_id: category.id, business_type: "general" } }
      }.not_to change(CustomerSubprofile, :count)
    end
  end
end
