# spec/models/purchase_spec.rb
require "rails_helper"

RSpec.describe Purchase, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:supplier).optional }
    it { should belong_to(:workflow).optional }
    it { should belong_to(:current_workflow_step).optional }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
    it { should have_many(:purchase_item_appointments).dependent(:destroy) }
    it { should have_many(:purchase_items).through(:purchase_item_appointments) }
    it { should have_many(:workflow_step_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:business_type) }

    it "rejects duplicate names within the same company" do
      company = create(:company)
      create(:purchase, company: company, name: "Pens restock")
      expect { create(:purchase, company: company, name: "Pens restock") }
        .to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
    end

    it "allows the same name in a different company" do
      create(:purchase, name: "Pens restock")
      expect { create(:purchase, name: "Pens restock") }.not_to raise_error
    end
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:currency) }
    it { should define_enum_for(:business_type).with_values(office_supply: 0, equipment: 1, service: 2) }
  end

  describe "#total_price" do
    it "sums the total_price of all purchase item appointments" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, company: purchase.company, name: "Pen")
      create(:purchase_item_appointment, purchase: purchase, purchase_item: item,
        quantity: 100, unit_price: 1.0, total_price: 100.0)
      create(:purchase_item_appointment, purchase: purchase, purchase_item: item,
        quantity: 5, unit_price: 2.0, total_price: 10.0)

      expect(purchase.total_price).to eq(110.0)
    end

    it "is zero without appointments" do
      expect(create(:purchase, name: "Empty buy").total_price).to eq(0.0)
    end
  end

  describe "workflow auto-binding on create" do
    # rails_helper disables company init (Company.skip_init) — seed the default workflow explicitly.
    let(:company) { create(:company) }

    before do
      Seed::WorkflowService.create(
        company: company, name: "Standard Purchase Process",
        process_type: :purchase_process, is_default: true
      ).tap do |workflow|
        Seed::WorkflowStepService.create(company: company, workflow: workflow, name: "Submit", position: 1)
        Seed::WorkflowStepService.create(company: company, workflow: workflow, name: "Manager Approval", position: 2)
      end
    end

    let(:default_workflow) { company.workflows.default_for(:purchase_process).first }

    it "binds the company's default purchase_process workflow and starts pending" do
      purchase = create(:purchase, company: company, name: "Pens restock")

      expect(purchase.workflow).to eq(default_workflow)
      expect(purchase.current_workflow_step).to eq(default_workflow.workflow_steps.order(:position).first)
      expect(purchase.reload.workflow_status_pending?).to be true
    end

    it "writes a submitted WorkflowStepLog for the creator" do
      employee = create(:employee, company: company)
      purchase = create(:purchase, company: company, name: "Pens restock", created_by_employee: employee)
      log = purchase.workflow_step_logs.sole

      expect(log.outcome_submitted?).to be true
      expect(log.employee_id).to eq(employee.id)
      expect(log.workflow_step_id).to eq(purchase.reload.current_workflow_step_id)
    end

    it "stays draft when the default workflow binding is skipped" do
      purchase = create(:purchase, company: company, name: "Pens restock", skip_default_workflow: true)

      expect(purchase.workflow).to be_nil
      expect(purchase.reload.workflow_status_draft?).to be true
    end

    it "stays draft when the company has no default workflow" do
      company.workflows.update_all(is_default: false)
      purchase = create(:purchase, company: company, name: "Pens restock")

      expect(purchase.workflow).to be_nil
      expect(purchase.reload.workflow_status_draft?).to be true
      expect(purchase.workflow_step_logs.count).to eq(0)
    end
  end

  it_behaves_like "property_mapping concern", Purchase
end
