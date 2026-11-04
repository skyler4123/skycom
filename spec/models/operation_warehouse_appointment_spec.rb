# spec/models/operation_warehouse_appointment_spec.rb
require "rails_helper"

RSpec.describe OperationWarehouseAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:operation) }
    it { should belong_to(:warehouse) }
  end

  describe "enums" do
    it { should define_enum_for(:workflow_status).with_values(inactive: 0, active: 1).with_prefix(:workflow_status) }
    it { should define_enum_for(:lifecycle_status).with_prefix(:lifecycle_status) }
  end

  describe "validations" do
    it "derives company_id from the operation" do
      company = create(:company)
      warehouse = create(:warehouse, company: company)
      operation = create(:operation, company: company, operation_type: :inventory)
      appointment = described_class.new(operation: operation, warehouse: warehouse)

      expect(appointment).to be_valid
      expect(appointment.company_id).to eq(company.id)
    end

    it "rejects a warehouse from another company" do
      company = create(:company)
      other_company = create(:company)
      operation = create(:operation, company: company, operation_type: :inventory)
      warehouse = create(:warehouse, company: other_company)
      appointment = described_class.new(company: company, operation: operation, warehouse: warehouse)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:warehouse]).to include("does not belong to this company")
    end

    it "requires metadata" do
      company = create(:company)
      warehouse = create(:warehouse, company: company)
      operation = create(:operation, company: company, operation_type: :inventory)
      appointment = build(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse, metadata: nil)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:metadata]).to include("can't be blank")
    end

    it "requires a unique warehouse per company and operation" do
      company = create(:company)
      warehouse = create(:warehouse, company: company)
      operation = create(:operation, company: company, operation_type: :inventory)
      create(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse)
      duplicate = build(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:operation_id]).to be_present
    end
  end

  describe ".active" do
    it "returns only active appointments" do
      company = create(:company)
      warehouse = create(:warehouse, company: company)
      other_warehouse = create(:warehouse, company: company)
      operation = create(:operation, company: company, operation_type: :inventory)
      active = create(:operation_warehouse_appointment, company: company, operation: operation, warehouse: warehouse)
      create(:operation_warehouse_appointment, :inactive, company: company, operation: operation, warehouse: other_warehouse)

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
