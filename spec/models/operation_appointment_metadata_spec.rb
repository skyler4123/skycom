# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Operation appointment local roles" do
  let(:company) { create(:company) }

  before do
    %w[Manager Cashier Seller].each do |name|
      company.roles.find_by(name: name) || Seed::RoleService.create(company: company, name: name)
    end
  end

  describe BranchOperationAppointment do
    it "accepts local roles inside the operation roles" do
      operation = create(:operation, company: company, metadata: { "roles" => %w[Manager Cashier] })
      branch = create(:branch, company: company)
      appointment = branch.branch_operation_appointments.find_by!(operation: operation)
      appointment.metadata = { "roles" => [ "Cashier" ] }

      expect(appointment).to be_valid
    end

    it "rejects local roles outside the operation roles" do
      operation = create(:operation, company: company, metadata: { "roles" => %w[Manager Cashier] })
      branch = create(:branch, company: company)
      appointment = branch.branch_operation_appointments.find_by!(operation: operation)
      appointment.metadata = { "roles" => [ "Seller" ] }

      expect(appointment).not_to be_valid
      expect(appointment.errors[:metadata]).to include("roles must be included in the operation roles")
    end

    it "rejects roles that are not company roles when the operation allows all" do
      operation = create(:operation, company: company, metadata: { "roles" => [] })
      branch = create(:branch, company: company)
      appointment = branch.branch_operation_appointments.find_by!(operation: operation)
      appointment.metadata = { "roles" => [ "Ghost" ] }

      expect(appointment).not_to be_valid
      expect(appointment.errors[:metadata]).to include("roles must be company roles")
    end
  end

  describe OperationWarehouseAppointment do
    it "accepts local roles inside the operation roles" do
      operation = create(
        :operation,
        company: company,
        operation_type: :inventory,
        metadata: { "roles" => %w[Manager Cashier] }
      )
      warehouse = create(:warehouse, company: company)
      appointment = warehouse.operation_warehouse_appointments.find_by!(operation: operation)
      appointment.metadata = { "roles" => [ "Manager" ] }

      expect(appointment).to be_valid
    end

    it "rejects local roles outside the operation roles" do
      operation = create(
        :operation,
        company: company,
        operation_type: :inventory,
        metadata: { "roles" => %w[Manager Cashier] }
      )
      warehouse = create(:warehouse, company: company)
      appointment = warehouse.operation_warehouse_appointments.find_by!(operation: operation)
      appointment.metadata = { "roles" => [ "Seller" ] }

      expect(appointment).not_to be_valid
      expect(appointment.errors[:metadata]).to include("roles must be included in the operation roles")
    end
  end
end
