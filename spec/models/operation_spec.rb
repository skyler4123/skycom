# spec/models/operation_spec.rb
require "rails_helper"

RSpec.describe Operation, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:branch_operation_appointments).dependent(:destroy) }
    it { should have_many(:branches).through(:branch_operation_appointments) }
    it { should have_many(:operation_warehouse_appointments).dependent(:destroy) }
    it { should have_many(:warehouses).through(:operation_warehouse_appointments) }
  end

  describe "enums" do
    it do
      should define_enum_for(:operation_type).with_values(
        pos: 100,
        booking: 200,
        inventory: 300,
        reception: 400,
        kitchen: 500,
        housekeeping: 600,
        store_manager: 700
      ).with_prefix(:operation_type)
    end

    it do
      should define_enum_for(:resolution).with_values(
        mobile: 10,
        desktop: 20
      ).with_prefix(:resolution)
    end
  end

  describe "validations" do
    subject { build(:operation) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:operation_type) }
    it { should validate_presence_of(:resolution) }

    it "requires metadata" do
      operation = build(:operation, metadata: nil)

      expect(operation).not_to be_valid
      expect(operation.errors[:metadata]).to include("can't be blank")
    end

    it "requires roles metadata to be an array of strings" do
      operation = build(:operation, metadata: { "roles" => "cashier" })

      expect(operation).not_to be_valid
      expect(operation.errors[:metadata]).to include("roles must be an array of strings")
    end

    it "allows empty roles metadata" do
      operation = build(:operation, metadata: { "roles" => [] })

      expect(operation).to be_valid
    end

    it "requires the operation type and resolution to be unique per company" do
      company = create(:company)
      create(:operation, company: company, operation_type: :pos, resolution: :desktop)
      duplicate = Operation.new(
        company: company,
        operation_type: :pos,
        resolution: :desktop,
        name: "Duplicate POS",
        code: "OP-DUP-#{SecureRandom.hex(3).upcase}"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:operation_type]).to be_present
    end
  end

  describe "#config_for" do
    it "deep-merges appointment metadata with operation metadata, operation winning" do
      operation = build(
        :operation,
        metadata: {
          "layout" => { "columns" => 12, "sidebar" => "operation" },
          "roles" => []
        }
      )
      appointment = BranchOperationAppointment.new(
        metadata: {
          "layout" => { "columns" => 6, "sidebar" => "appointment", "theme" => "dark" },
          "roles" => [ "Cashier" ]
        }
      )

      expect(operation.config_for(appointment)).to eq(
        "layout" => { "columns" => 12, "sidebar" => "operation", "theme" => "dark" },
        "roles" => []
      )
    end

    it "returns operation metadata when the appointment has none" do
      operation = build(:operation, metadata: { "roles" => [ "Cashier" ] })
      appointment = BranchOperationAppointment.new(metadata: {})

      expect(operation.config_for(appointment)).to eq("roles" => [ "Cashier" ])
    end
  end

  describe "#accessible_by?" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:employee) { create(:employee, company: company, branch: branch) }

    it "allows everyone with Operation read when roles are empty" do
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [] })

      expect(operation.accessible_by?(employee)).to be(true)
    end

    it "allows an employee with a matching role" do
      employee.attach_role("Cashier")
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [ "Cashier" ] })

      expect(operation.accessible_by?(employee)).to be(true)
    end

    it "denies an employee without a matching role" do
      employee.attach_role("Cashier")
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [ "Manager" ] })

      expect(operation.accessible_by?(employee)).to be(false)
    end

    it "allows the owner regardless of roles" do
      owner = company.employees.find_by!(business_type: OWNER_BUSINESS_TYPE)
      owner.update!(branch: branch)
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [ "Manager" ] })

      expect(operation.accessible_by?(owner)).to be(true)
    end
  end
end
