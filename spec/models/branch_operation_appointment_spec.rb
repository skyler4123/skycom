# spec/models/branch_operation_appointment_spec.rb
require "rails_helper"

RSpec.describe BranchOperationAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
    it { should belong_to(:operation) }
  end

  describe "enums" do
    it { should define_enum_for(:workflow_status).with_values(inactive: 0, active: 1).with_prefix(:workflow_status) }
    it { should define_enum_for(:lifecycle_status).with_prefix(:lifecycle_status) }
  end

  describe "validations" do
    it "derives company_id from the branch" do
      company = create(:company)
      branch = create(:branch, company: company)
      operation = create(:operation, company: company)
      appointment = described_class.new(branch: branch, operation: operation)

      expect(appointment).to be_valid
      expect(appointment.company_id).to eq(company.id)
    end

    it "rejects a branch from another company" do
      company = create(:company)
      other_company = create(:company)
      branch = create(:branch, company: other_company)
      operation = create(:operation, company: company)
      appointment = described_class.new(company: company, branch: branch, operation: operation)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:branch]).to include("does not belong to this company")
    end

    it "rejects a operation from another company" do
      company = create(:company)
      other_company = create(:company)
      branch = create(:branch, company: company)
      operation = create(:operation, company: other_company)
      appointment = described_class.new(company: company, branch: branch, operation: operation)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:operation]).to include("does not belong to this company")
    end

    it "requires metadata" do
      company = create(:company)
      branch = create(:branch, company: company)
      operation = create(:operation, company: company)
      appointment = build(:branch_operation_appointment, company: company, branch: branch, operation: operation, metadata: nil)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:metadata]).to include("can't be blank")
    end

    it "requires a unique branch per company and operation" do
      company = create(:company)
      branch = create(:branch, company: company)
      operation = create(:operation, company: company)
      create(:branch_operation_appointment, company: company, branch: branch, operation: operation)
      duplicate = build(:branch_operation_appointment, company: company, branch: branch, operation: operation)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:operation_id]).to be_present
    end
  end

  describe ".active" do
    it "returns only active appointments" do
      company = create(:company)
      branch = create(:branch, company: company)
      operation = create(:operation, company: company)
      active = create(:branch_operation_appointment, company: company, branch: branch, operation: operation)
      create(:branch_operation_appointment, :inactive, company: company, branch: branch, operation: create(:operation, company: company, operation_type: :booking))

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
