# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::OperationsController", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company, name: "Main Branch") }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Main Warehouse") }

  before do
    Seed::OperationService.seed_defaults!(company: company)
    get sign_in_for_test_path(email: owner.email)
  end

  describe "GET #index" do
    it "lists branch and warehouse appointments with their effective config" do
      pos_operation = company.operations.find_by!(operation_type: :pos)
      pos_operation.update!(metadata: { "roles" => [], "layout" => { "columns" => 12 } })
      branch_appointment = branch.branch_operation_appointments.find_by!(operation: pos_operation)
      branch_appointment.update!(metadata: { "layout" => { "columns" => 6 }, "theme" => "dark" })

      get company_operations_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      kinds = body.fetch("operation_appointments").map { |appointment| appointment.fetch("kind") }
      expect(kinds).to include("branch", "warehouse")

      appointment = body.fetch("operation_appointments").find { |row| row.fetch("id") == branch_appointment.id }
      expect(appointment.fetch("operation").fetch("operation_type")).to eq("pos")
      expect(appointment.fetch("location")).to eq("id" => branch.id, "name" => "Main Branch")
      expect(appointment.fetch("branch")).to eq("id" => branch.id, "name" => "Main Branch")
      expect(appointment.fetch("effective_config")).to eq(
        "roles" => [],
        "layout" => { "columns" => 6 },
        "theme" => "dark"
      )
      expect(appointment.fetch("launch_path")).to include("/operations/#{pos_operation.id}/launch")
      expect(appointment.fetch("accessible")).to be(true)
    end

    it "does not expose another company's appointments" do
      other_company = create(:company)
      other_branch = create(:branch, company: other_company, name: "Other Branch")
      Seed::OperationService.seed_defaults!(company: other_company)

      get company_operations_path(other_company), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(other_branch.branch_operation_appointments.count).to be > 0
    end

    it "filters appointments by operation type" do
      get company_operations_path(company, operation_type: "pos"), as: :json

      rows = JSON.parse(response.body).fetch("operation_appointments")
      expect(rows).not_to be_empty
      expect(rows).to all(satisfy { |row| row.dig("operation", "operation_type") == "pos" })
    end

    it "filters appointments by location" do
      get company_operations_path(company, location: "branch:#{branch.id}"), as: :json

      rows = JSON.parse(response.body).fetch("operation_appointments")
      expect(rows).not_to be_empty
      expect(rows).to all(satisfy { |row| row.fetch("kind") == "branch" && row.dig("location", "id") == branch.id })
    end

    it "filters appointments by status" do
      pos_operation = company.operations.find_by!(operation_type: :pos)
      branch.branch_operation_appointments.find_by!(operation: pos_operation).update!(workflow_status: :inactive)

      get company_operations_path(company, workflow_status: "inactive"), as: :json

      rows = JSON.parse(response.body).fetch("operation_appointments")
      expect(rows).not_to be_empty
      expect(rows).to all(satisfy { |row| row.fetch("workflow_status") == "inactive" })
    end

    it "filters appointments by keyword" do
      get company_operations_path(company, q: "POS"), as: :json

      rows = JSON.parse(response.body).fetch("operation_appointments")
      expect(rows).not_to be_empty
      expect(rows).to all(satisfy { |row| row.dig("operation", "name").to_s.downcase.include?("pos") })
    end

    it "returns filter options for the index page" do
      get company_operations_path(company), as: :json

      filters = JSON.parse(response.body).fetch("filters")
      expect(filters.fetch("operation_types")).to include("value" => "pos", "name" => "POS")
      expect(filters.fetch("statuses").map { |status| status.fetch("value") }).to include("active", "inactive")
      expect(filters.fetch("locations")).to include(
        "value" => "branch:#{branch.id}",
        "name" => branch.name,
        "kind" => "branch"
      )
    end

    it "caches the index payload and invalidates it when an operation changes" do
      get company_operations_path(company), as: :json

      cache_key = CacheKeyService.company_operation_appointments(company.id)
      expect(Rails.sync_cache.read(cache_key)).to be_present

      pos_operation = company.operations.find_by!(operation_type: :pos)
      pos_operation.update!(metadata: { "roles" => [], "layout" => { "columns" => 8 } })

      expect(Rails.sync_cache.read(cache_key)).to be_nil

      get company_operations_path(company), as: :json
      row = JSON.parse(response.body).fetch("operation_appointments").find do |appointment|
        appointment.dig("operation", "id") == pos_operation.id
      end
      expect(row.dig("effective_config", "layout", "columns")).to eq(8)
    end

    it "invalidates the cache when an appointment changes" do
      get company_operations_path(company), as: :json

      cache_key = CacheKeyService.company_operation_appointments(company.id)
      expect(Rails.sync_cache.read(cache_key)).to be_present

      pos_operation = company.operations.find_by!(operation_type: :pos)
      branch.branch_operation_appointments.find_by!(operation: pos_operation).update!(workflow_status: :inactive)

      expect(Rails.sync_cache.read(cache_key)).to be_nil
    end

    it "invalidates the cache when a location is renamed" do
      get company_operations_path(company), as: :json

      cache_key = CacheKeyService.company_operation_appointments(company.id)
      expect(Rails.sync_cache.read(cache_key)).to be_present

      branch.update!(name: "Renamed Branch")

      expect(Rails.sync_cache.read(cache_key)).to be_nil

      get company_operations_path(company), as: :json
      expect(response.body).to include("Renamed Branch")
    end
  end

  describe "GET #launch" do
    it "redirects to the POS operation with the branch appointment" do
      pos_operation = company.operations.find_by!(operation_type: :pos)
      appointment = branch.branch_operation_appointments.find_by!(operation: pos_operation)

      get launch_company_operation_path(company, pos_operation, branch_id: branch.id)

      expect(response).to have_http_status(:found)
      expect(response.location).to include(
        "/companies/#{company.id}/operations/pos/#{pos_operation.id}",
        "branch_id=#{branch.id}"
      )
      expect(appointment).to be_workflow_status_active
    end

    it "returns the launch path as JSON" do
      pos_operation = company.operations.find_by!(operation_type: :pos)

      get launch_company_operation_path(company, pos_operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("launch_path")).to include("/operations/pos/#{pos_operation.id}")
    end

    it "rejects an inactive appointment" do
      pos_operation = company.operations.find_by!(operation_type: :pos)
      branch.branch_operation_appointments.find_by!(operation: pos_operation).update!(workflow_status: :inactive)

      get launch_company_operation_path(company, pos_operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("errors")).to include("This operation is inactive.")
    end

    it "rejects an operation whose roles do not match the employee" do
      pos_operation = company.operations.find_by!(operation_type: :pos)
      pos_operation.update!(metadata: { "roles" => [ "Manager" ] })
      employee = create(:employee, company: company, branch: branch)
      role = employee.attach_role("Cashier")
      policy = Policy.create!(
        company: company,
        name: "Operation read",
        resource: "Operation",
        action: "read",
        lifecycle_status: :active,
        workflow_status: :confirmed
      )
      PolicyRoleAppointment.create!(company: company, policy: policy, role: role, workflow_status: :active)
      get sign_in_for_test_path(email: employee.user.email)

      get launch_company_operation_path(company, pos_operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).fetch("errors")).to include("You do not have access to this operation.")
    end

    it "rejects an appointment whose local roles exclude the employee" do
      %w[Manager Cashier].each do |name|
        company.roles.find_by(name: name) || Seed::RoleService.create(company: company, name: name)
      end
      pos_operation = company.operations.find_by!(operation_type: :pos)
      pos_operation.update!(metadata: { "roles" => %w[Manager Cashier] })
      branch.branch_operation_appointments.find_by!(operation: pos_operation).update!(metadata: { "roles" => [ "Manager" ] })
      employee = create(:employee, company: company, branch: branch)
      role = employee.attach_role("Cashier")
      policy = Policy.create!(
        company: company,
        name: "Operation read",
        resource: "Operation",
        action: "read",
        lifecycle_status: :active,
        workflow_status: :confirmed
      )
      PolicyRoleAppointment.create!(company: company, policy: policy, role: role, workflow_status: :active)
      get sign_in_for_test_path(email: employee.user.email)

      get launch_company_operation_path(company, pos_operation, branch_id: branch.id), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).fetch("errors")).to include("You do not have access to this operation.")
    end
  end

  describe "removed CRUD routes" do
    it "has no new, create, show, edit, or update Operation routes" do
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/operations/new", method: :get)
      }.to raise_error(ActionController::RoutingError)
      expect {
        Rails.application.routes.recognize_path("/companies/#{company.id}/operations", method: :post)
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
