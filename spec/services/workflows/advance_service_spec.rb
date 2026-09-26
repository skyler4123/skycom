# spec/services/workflows/advance_service_spec.rb
require "rails_helper"

RSpec.describe Workflows::AdvanceService do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: "owner") }
  let(:employee) { create(:employee, company: company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases") }

  # rails_helper disables company init (Company.skip_init) — seed the category's workflow explicitly.
  # Category is the bridge: the purchase binds its category's default workflow (docs/PURCHASE_WORKFLOW.md).
  let!(:workflow) do
    Seed::WorkflowService.create(
      company: company, category: category, name: "Standard Purchase Process",
      process_type: :purchase_process
    ).tap do |workflow|
      [
        { name: "Submit", position: 1 },
        { name: "Manager Approval", position: 2 },
        { name: "Buy", position: 3 },
        { name: "Complete", position: 4 }
      ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
    end
  end

  let!(:purchase) do
    create(:purchase, company: company, category: category, name: "Pens restock", created_by_employee: employee)
  end

  def advance(outcome:, employee:, note: nil, target_step: nil)
    described_class.call(
      subject: purchase, employee: employee, outcome: outcome, note: note, target_step: target_step
    )
  end

  def step_at(position)
    workflow.workflow_steps.find_by(position: position)
  end

  describe "approved" do
    it "moves the pointer to the next step and marks the subject confirmed" do
      expect(advance(outcome: :approved, employee: owner)).to eq({ success: true })

      expect(purchase.reload.workflow_step).to eq(step_at(2))
      expect(purchase.workflow_status_confirmed?).to be true
    end

    it "completes the workflow on the final step" do
      advance(outcome: :approved, employee: owner)
      advance(outcome: :approved, employee: owner)
      advance(outcome: :approved, employee: owner)

      expect(advance(outcome: :approved, employee: owner)).to eq({ success: true })
      expect(purchase.reload.workflow_status_completed?).to be true
      expect(purchase.reload.workflow_step).to eq(step_at(4))
    end

    it "bridges stock on final approval: import + ledger + quantity (purchase with stocked items)" do
      product = create(:product, company: company)
      item = Seed::PurchaseItemService.create(company: company, product: product, name: "Pen box")
      purchase.purchase_item_appointments.create!(
        company: company, purchase_item: item, quantity: 5, unit_price: 2, total_price: 10
      )

      3.times { advance(outcome: :approved, employee: owner) }

      expect {
        advance(outcome: :approved, employee: owner)
      }.to change(StockTransaction, :count).by(1)

      stock = Stock.find_by!(company: company, warehouse: purchase.reload.warehouse, product: product)
      expect(stock.quantity).to eq(5)
      import = StockImport.find_by(appoint_from_type: "Purchase", appoint_from_id: purchase.id)
      expect(import.workflow_status).to eq("received")
    end

    it "still completes a bare purchase (no line items) — bridge skips" do
      3.times { advance(outcome: :approved, employee: owner) }

      expect(advance(outcome: :approved, employee: owner)).to eq({ success: true })
      expect(purchase.reload.workflow_status_completed?).to be true
      expect(StockImport.where(appoint_from_type: "Purchase", appoint_from_id: purchase.id)).to be_empty
    end

    it "records an approved log with the actor and from-step" do
      expect { advance(outcome: :approved, employee: owner) }.to change(WorkflowStepLog, :count).by(1)

      log = purchase.workflow_step_logs.last
      expect(log.outcome_approved?).to be true
      expect(log.employee_id).to eq(owner.id)
      expect(log.from_step_id).to eq(step_at(1).id)
    end
  end

  describe "rejected" do
    it "cancels the subject and leaves the pointer unchanged" do
      advance(outcome: :approved, employee: owner)

      expect(advance(outcome: :rejected, employee: owner)).to eq({ success: true })
      expect(purchase.reload.workflow_status_cancelled?).to be true
      expect(purchase.reload.workflow_step).to eq(step_at(2))
    end
  end

  describe "rework" do
    it "moves the pointer back to the target step and marks pending" do
      advance(outcome: :approved, employee: owner)

      expect(advance(outcome: :rework, employee: owner, target_step: step_at(1))).to eq({ success: true })
      expect(purchase.reload.workflow_step).to eq(step_at(1))
      expect(purchase.reload.workflow_status_pending?).to be true
    end

    it "records the target step in the log metadata" do
      advance(outcome: :approved, employee: owner)
      advance(outcome: :rework, employee: owner, target_step: step_at(1))

      expect(purchase.workflow_step_logs.last.target_step_id).to eq(step_at(1).id)
    end

    it "rejects a target step from another workflow" do
      other_category = create(:category, company: company, name: "Other supplies", resource_name: "purchase_items")
      other = create(:workflow, company: company, category: other_category, name: "Other flow")
      foreign_step = create(:workflow_step, workflow: other, name: "Foreign", position: 1)
      advance(outcome: :approved, employee: owner)

      expect(advance(outcome: :rework, employee: owner, target_step: foreign_step)).to eq(
        { success: false, errors: [ "Rework target must belong to the same workflow" ] }
      )
    end

    it "fails without a target step" do
      expect(advance(outcome: :rework, employee: owner)).to eq(
        { success: false, errors: [ "Rework target step is required" ] }
      )
    end
  end

  describe "guards" do
    it "fails for a subject without a bound workflow" do
      draft = create(:purchase, company: company, category: category, name: "Draft buy", skip_workflow: true)

      result = described_class.call(subject: draft, employee: owner, outcome: :approved)

      expect(result).to eq({ success: false, errors: [ "Subject has no active workflow" ] })
    end

    it "fails without an employee" do
      expect(advance(outcome: :approved, employee: nil)).to eq(
        { success: false, errors: [ "Employee is required" ] }
      )
    end

    it "fails for an invalid outcome" do
      expect(advance(outcome: :submitted, employee: owner)).to eq(
        { success: false, errors: [ "Invalid outcome" ] }
      )
    end

    it "fails for an employee without update permission and writes no log" do
      no_policy_employee = create(:employee, company: company)

      expect(advance(outcome: :approved, employee: no_policy_employee)).to eq(
        { success: false, errors: [ "You are not authorized to update this record" ] }
      )

      expect(purchase.reload.workflow_step).to eq(step_at(1))
      expect(purchase.workflow_step_logs.where(outcome: :approved).count).to eq(0)
    end

    it "fails to advance an already completed workflow" do
      advance(outcome: :approved, employee: owner)
      advance(outcome: :approved, employee: owner)
      advance(outcome: :approved, employee: owner)
      advance(outcome: :approved, employee: owner)

      expect(advance(outcome: :approved, employee: owner)).to eq(
        { success: false, errors: [ "Workflow already completed" ] }
      )
    end

    it "fails to advance a cancelled workflow" do
      advance(outcome: :rejected, employee: owner)

      expect(advance(outcome: :approved, employee: owner)).to eq(
        { success: false, errors: [ "Workflow was cancelled" ] }
      )
    end
  end

  describe "ABAC as the source of truth" do
    let(:purchaser_role) { create(:role, company: company, name: "Purchaser") }
    let(:member) { create(:employee, company: company).tap { |e| e.attach_role("Purchaser") } }

    before do
      policy = Seed::PolicyService.create(
        company: company, name: "Update Purchase",
        resource: "Purchase", action: "update",
        business_type: :operational, lifecycle_status: :active
      )
      Seed::PolicyAppointmentService.create(company: company, policy: policy, appoint_to: purchaser_role)
    end

    it "allows a non-owner employee whose role holds the update policy" do
      expect(member.can?(:update, purchase)).to be true

      expect(advance(outcome: :approved, employee: member)).to eq({ success: true })
      expect(purchase.reload.workflow_step).to eq(step_at(2))
    end
  end
end
