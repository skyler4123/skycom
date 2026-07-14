# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Toast message responses", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:headers) { { "ACCEPT" => "application/json" } }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "ProductsController#update" do
    let(:product) { create(:product, company: company) }

    it "returns message in JSON success response" do
      patch "/companies/#{company.id}/products/#{product.id}",
        params: { product: { name: "Updated Name" } }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Product updated successfully")
    end
  end

  describe "BranchesController#update" do
    let(:branch) { create(:branch, company: company) }

    it "returns message in JSON success response" do
      patch "/companies/#{company.id}/branches/#{branch.id}",
        params: { branch: { name: "Updated Branch" } }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Branch updated successfully")
    end
  end

  describe "DepartmentsController#update" do
    let(:department) { create(:department, company: company) }

    it "returns message in JSON success response" do
      patch "/companies/#{company.id}/departments/#{department.id}",
        params: { department: { name: "Updated Dept" } }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Department updated successfully")
    end
  end

  describe "ServicesController#update" do
    let(:svc_company) { create(:company) }
    let(:svc_branch) { create(:branch, company: svc_company) }
    let(:svc_owner) { svc_company.user }
    let(:svc_category) do
      Seed::CategoryService.find_or_create_for(company: svc_company, resource_name: "services")
    end
    let(:svc) do
      s = Seed::ServiceService.create(
        company: svc_company,
        branch: svc_branch,
        category: svc_category,
        property_mapping: svc_category.default_property_mapping,
        name: "Test Service",
        business_type: :b2c
      )
      s
    end

    it "returns message in JSON success response" do
      get sign_in_for_test_path(email: svc_owner.email)
      patch "/companies/#{svc_company.id}/services/#{svc.id}",
        params: { service: { name: "Updated Service" } }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Service updated successfully")
    end
  end

  describe "BrandsController#update" do
    let(:category) { create(:category, company: company) }
    let(:brand) { create(:brand, company: company, category: category) }

    it "returns message in JSON success response" do
      patch "/companies/#{company.id}/brands/#{brand.id}",
        params: { brand: { name: "Updated Brand" } }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Brand updated successfully")
    end
  end

  describe "PermissionsController#update" do
    let(:perm_company) { create(:company) }
    let(:perm_owner) { perm_company.user }
    let(:perm_branch) { create(:branch, company: perm_company) }
    let(:perm_role) { create(:role, company: perm_company) }
    let(:perm_policy) { Seed::PolicyService.create(branch: perm_branch, resource: "Product", action: "read", name: "Test Policy") }
    let!(:appointment) do
      Seed::PolicyAppointmentService.create(
        policy: perm_policy,
        appoint_to: perm_role,
        company: perm_company,
        workflow_status: :active
      )
    end

    it "returns message when toggling permission status" do
      get sign_in_for_test_path(email: perm_owner.email)
      patch "/companies/#{perm_company.id}/permissions/#{appointment.id}",
        params: { policy_appointment: { workflow_status: false } }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Permission updated successfully")
    end
  end

  describe "OrderProcessing::V1#checkout" do
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

    before do
      stock.send(:sync_available_counter)
    end

    it "returns message in checkout response" do
      post "/companies/#{company.id}/order_processing/v1/checkout",
        params: { branch_id: branch.id, items: [ { stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 } ] },
        headers: headers
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Order created")
    end
  end

  describe "OrderProcessing::V1#pay" do
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company) }
    let(:customer) { create(:customer, company: company) }
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

    before do
      stock.send(:sync_available_counter)
    end

    it "returns message in pay response" do
      post "/companies/#{company.id}/order_processing/v1/pay",
        params: { order_id: order.id }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Payment completed")
    end
  end

  describe "CompaniesController#create" do
    it "returns message in JSON success response" do
      post "/companies",
        params: { company: { name: "New Co", business_type: "retail" } }, headers: headers
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Company created successfully")
    end
  end
end
