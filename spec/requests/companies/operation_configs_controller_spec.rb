# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OperationConfigsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    Seed::OperationService.seed_defaults!(company: company)
    get sign_in_for_test_path(email: owner.email)
  end

  describe "GET #index" do
    it "lists every company operation with appointment counts" do
      get company_operation_configs_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("operation_configs").size).to eq(OPERATION_TYPES.size)

      pos = body.fetch("operation_configs").find { |operation| operation.fetch("operation_type") == "pos" }
      expect(pos.fetch("branch_appointment_count")).to eq(1)
      expect(pos.fetch("operation_warehouse_appointment_count")).to eq(0)

      inventory = body.fetch("operation_configs").find { |operation| operation.fetch("operation_type") == "inventory" }
      expect(inventory.fetch("operation_warehouse_appointment_count")).to eq(1)
    end
  end

  describe "GET #show" do
    it "returns the operation config with appointment counts" do
      operation = company.operations.find_by!(operation_type: :pos)

      get company_operation_config_path(company, operation), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body).fetch("operation_config")
      expect(body.fetch("operation_type")).to eq("pos")
      expect(body.fetch("branch_appointment_count")).to eq(1)
      expect(body.fetch("operation_warehouse_appointment_count")).to eq(0)
    end

    it "does not expose another company's operation" do
      other_company = create(:company)
      other_operation = create(:operation, company: other_company)

      get company_operation_config_path(company, other_operation), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #edit" do
    it "renders the edit page shell" do
      operation = company.operations.find_by!(operation_type: :pos)

      get edit_company_operation_config_path(company, operation)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "updates metadata and returns the operation" do
      operation = company.operations.find_by!(operation_type: :pos)

      patch company_operation_config_path(company, operation), params: {
        operation: { metadata: { "roles" => [ "Cashier" ], "layout" => { "columns" => 8 } } }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("message")).to eq("Operation config updated.")
      expect(body.fetch("operation").fetch("metadata")).to eq(
        "roles" => [ "Cashier" ],
        "layout" => { "columns" => 8 }
      )
      expect(operation.reload.metadata).to eq("roles" => [ "Cashier" ], "layout" => { "columns" => 8 })
    end

    it "ignores non-metadata params" do
      operation = company.operations.find_by!(operation_type: :pos)
      original_name = operation.name

      patch company_operation_config_path(company, operation), params: {
        operation: { name: "Hacked", operation_type: "booking", metadata: { "roles" => [] } }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(operation.reload.name).to eq(original_name)
      expect(operation.operation_type).to eq("pos")
    end

    it "rejects invalid roles metadata" do
      operation = company.operations.find_by!(operation_type: :pos)

      patch company_operation_config_path(company, operation), params: {
        operation: { metadata: { "roles" => "Cashier" } }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("errors")).to include("Metadata roles must be an array of strings")
    end

    it "does not expose another company's operation" do
      other_company = create(:company)
      other_operation = create(:operation, company: other_company)

      patch company_operation_config_path(company, other_operation), params: {
        operation: { metadata: { "roles" => [] } }
      }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "redirects to the show page after an HTML update" do
      operation = company.operations.find_by!(operation_type: :pos)

      patch company_operation_config_path(company, operation), params: {
        operation: { metadata: { "roles" => [ "Cashier" ] } }
      }

      expect(response).to redirect_to(company_operation_config_path(company, operation))
      expect(flash[:notice]).to eq("Operation config updated.")
      expect(operation.reload.metadata).to eq("roles" => [ "Cashier" ])
    end
  end
end
