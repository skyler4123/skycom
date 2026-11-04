# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Company operation appointment updates", type: :request do
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

  describe "GET #show" do
    it "returns a branch appointment payload" do
      appointment = branch.branch_operation_appointments.find_by!(operation: company.operations.find_by!(operation_type: :pos))

      get company_branch_operation_appointment_path(company, appointment), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body).fetch("appointment")
      expect(body.fetch("kind")).to eq("branch")
      expect(body.fetch("location")).to eq("id" => branch.id, "name" => branch.name)
      expect(body.fetch("operation").fetch("operation_type")).to eq("pos")
    end

    it "returns a warehouse appointment payload" do
      appointment = warehouse.operation_warehouse_appointments.find_by!(
        operation: company.operations.find_by!(operation_type: :inventory)
      )

      get company_operation_warehouse_appointment_path(company, appointment), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body).fetch("appointment")
      expect(body.fetch("kind")).to eq("warehouse")
      expect(body.fetch("location")).to eq("id" => warehouse.id, "name" => warehouse.name)
    end

    it "does not expose another company's appointment" do
      other_company = create(:company)
      other_branch = create(:branch, company: other_company)
      Seed::OperationService.seed_defaults!(company: other_company)
      other_appointment = other_branch.branch_operation_appointments.first

      get company_branch_operation_appointment_path(company, other_appointment), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #edit" do
    it "renders the branch appointment edit page shell" do
      appointment = branch.branch_operation_appointments.first

      get edit_company_branch_operation_appointment_path(company, appointment)

      expect(response).to have_http_status(:ok)
    end

    it "renders the warehouse appointment edit page shell" do
      appointment = warehouse.operation_warehouse_appointments.first

      get edit_company_operation_warehouse_appointment_path(company, appointment)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update for a branch appointment" do
    it "updates metadata and workflow status" do
      appointment = branch.branch_operation_appointments.find_by!(operation: company.operations.find_by!(operation_type: :pos))

      patch company_branch_operation_appointment_path(company, appointment), params: {
        branch_operation_appointment: {
          metadata: { "layout" => { "columns" => 6 } },
          workflow_status: "inactive"
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("message")).to eq("Operation appointment updated.")
      expect(body.fetch("appointment").fetch("workflow_status")).to eq("inactive")
      expect(appointment.reload.metadata).to eq("layout" => { "columns" => 6 })
      expect(appointment).to be_workflow_status_inactive
    end

    it "redirects to the appointment show page after an HTML update" do
      appointment = branch.branch_operation_appointments.find_by!(operation: company.operations.find_by!(operation_type: :pos))

      patch company_branch_operation_appointment_path(company, appointment), params: {
        branch_operation_appointment: { workflow_status: "inactive" }
      }

      expect(response).to redirect_to(company_branch_operation_appointment_path(company, appointment))
      expect(flash[:notice]).to eq("Operation appointment updated.")
    end

    it "rejects an unknown workflow status" do
      appointment = branch.branch_operation_appointments.first

      patch company_branch_operation_appointment_path(company, appointment), params: {
        branch_operation_appointment: { workflow_status: "not-a-status" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("errors")).to include("Invalid workflow status")
    end

    it "does not update another company's appointment" do
      other_company = create(:company)
      other_branch = create(:branch, company: other_company)
      Seed::OperationService.seed_defaults!(company: other_company)
      other_appointment = other_branch.branch_operation_appointments.first

      patch company_branch_operation_appointment_path(company, other_appointment), params: {
        branch_operation_appointment: { workflow_status: "inactive" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH #update for a warehouse appointment" do
    it "updates metadata and workflow status" do
      appointment = warehouse.operation_warehouse_appointments.find_by!(
        operation: company.operations.find_by!(operation_type: :inventory)
      )

      patch company_operation_warehouse_appointment_path(company, appointment), params: {
        operation_warehouse_appointment: {
          metadata: { "bin" => "A1" },
          workflow_status: "inactive"
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(appointment.reload.metadata).to eq("bin" => "A1")
      expect(appointment).to be_workflow_status_inactive
    end
  end
end
