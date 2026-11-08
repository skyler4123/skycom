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
        store_manager: 700
      ).with_prefix(:operation_type)
    end
  end

  describe "validations" do
    subject { build(:operation) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:operation_type) }
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

    it "requires the operation type to be unique per company" do
      company = create(:company)
      create(:operation, company: company, operation_type: :pos)
      duplicate = Operation.new(
        company: company,
        operation_type: :pos,
        name: "Duplicate POS",
        code: "OP-DUP-#{SecureRandom.hex(3).upcase}"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:operation_type]).to be_present
    end
  end

  describe "#config_for" do
    it "deep-merges operation metadata with appointment metadata, appointment winning" do
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
        "layout" => { "columns" => 6, "sidebar" => "appointment", "theme" => "dark" },
        "roles" => [ "Cashier" ]
      )
    end

    it "returns operation metadata when the appointment has none" do
      operation = build(:operation, metadata: { "roles" => [ "Cashier" ] })
      appointment = BranchOperationAppointment.new(metadata: {})

      expect(operation.config_for(appointment)).to eq("roles" => [ "Cashier" ])
    end

    it "inherits operation roles when the appointment roles are empty" do
      operation = build(:operation, metadata: { "roles" => [ "Manager" ], "layout" => { "columns" => 12 } })
      appointment = BranchOperationAppointment.new(metadata: { "roles" => [], "layout" => { "columns" => 6 } })

      expect(operation.config_for(appointment)).to eq(
        "roles" => [ "Manager" ],
        "layout" => { "columns" => 6 }
      )
    end

    it "does not let an appointment widen operation roles" do
      operation = build(:operation, metadata: { "roles" => [ "Manager" ] })
      appointment = BranchOperationAppointment.new(metadata: { "roles" => [ "Cashier" ] })

      expect(operation.config_for(appointment)).to eq("roles" => [])
    end
  end

  describe "#effective_roles" do
    it "uses appointment roles when they narrow the operation roles" do
      operation = build(:operation, metadata: { "roles" => [ "Manager", "Cashier" ] })
      appointment = BranchOperationAppointment.new(metadata: { "roles" => [ "Cashier" ] })

      expect(operation.effective_roles(appointment)).to eq([ "Cashier" ])
    end

    it "falls back to operation roles when appointment roles are empty" do
      operation = build(:operation, metadata: { "roles" => [ "Manager" ] })
      appointment = BranchOperationAppointment.new(metadata: { "roles" => [] })

      expect(operation.effective_roles(appointment)).to eq([ "Manager" ])
    end

    it "returns the intersection when appointment roles are outside the operation roles" do
      operation = build(:operation, metadata: { "roles" => [ "Manager" ] })
      appointment = BranchOperationAppointment.new(metadata: { "roles" => [ "Cashier" ] })

      expect(operation.effective_roles(appointment)).to eq([])
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

    it "narrows access when the appointment local roles exclude the employee" do
      employee.attach_role("Cashier")
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [ "Manager", "Cashier" ] })
      appointment = BranchOperationAppointment.new(operation: operation, branch: branch, metadata: { "roles" => [ "Manager" ] })

      expect(operation.accessible_by?(employee, appointment: appointment)).to be(false)
    end

    it "allows access when the appointment local roles include the employee" do
      employee.attach_role("Cashier")
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [ "Manager", "Cashier" ] })
      appointment = BranchOperationAppointment.new(operation: operation, branch: branch, metadata: { "roles" => [ "Cashier" ] })

      expect(operation.accessible_by?(employee, appointment: appointment)).to be(true)
    end

    it "does not widen access when local roles fall outside the operation roles" do
      employee.attach_role("Cashier")
      operation = create(:operation, company: company, branch: branch, metadata: { "roles" => [ "Manager" ] })
      appointment = BranchOperationAppointment.new(operation: operation, branch: branch, metadata: { "roles" => [ "Cashier" ] })

      expect(operation.accessible_by?(employee, appointment: appointment)).to be(false)
    end
  end

  describe "company metadata reset" do
    it "copies operation metadata to every branch appointment when metadata changes" do
      company = create(:company)
      branch = create(:branch, company: company)
      Seed::OperationService.seed_defaults!(company: company)
      operation = company.operations.find_by!(operation_type: :pos)
      appointment = branch.branch_operation_appointments.find_by!(operation: operation)
      appointment.update!(metadata: { "layout" => { "columns" => 6 } })

      operation.update!(metadata: { "roles" => [ "Manager" ], "layout" => { "columns" => 12 } })

      expect(appointment.reload.metadata).to eq(operation.metadata)
    end

    it "copies operation metadata to every warehouse appointment when metadata changes" do
      company = create(:company)
      branch = create(:branch, company: company)
      warehouse = create(:warehouse, company: company, branch: branch)
      Seed::OperationService.seed_defaults!(company: company)
      operation = company.operations.find_by!(operation_type: :inventory)
      appointment = warehouse.operation_warehouse_appointments.find_by!(operation: operation)
      appointment.update!(metadata: { "bin" => "A1" })

      operation.update!(metadata: { "roles" => [ "Manager" ], "bin" => "B2" })

      expect(appointment.reload.metadata).to eq(operation.metadata)
    end

    it "does not reset appointments when a non-metadata attribute changes" do
      company = create(:company)
      branch = create(:branch, company: company)
      Seed::OperationService.seed_defaults!(company: company)
      operation = company.operations.find_by!(operation_type: :pos)
      appointment = branch.branch_operation_appointments.find_by!(operation: operation)
      appointment.update!(metadata: { "layout" => { "columns" => 6 } })

      operation.update!(description: "Updated description")

      expect(appointment.reload.metadata).to eq("layout" => { "columns" => 6 })
    end
  end
end
