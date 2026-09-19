# spec/models/workflow_step_log_spec.rb
require "rails_helper"

RSpec.describe WorkflowStepLog, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:workflow) }
    it { should belong_to(:workflow_step) }
    it { should belong_to(:employee).optional }
    it { should belong_to(:subject) }
  end

  describe "validations" do
    it { should validate_presence_of(:outcome) }
  end

  describe "enums" do
    it { should define_enum_for(:outcome) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }

    it "defines outcome values" do
      expect(WorkflowStepLog.outcomes).to eq(
        "submitted" => 0, "approved" => 1, "rejected" => 2, "rework" => 3
      )
    end
  end

  describe "metadata accessors" do
    it "exposes from_step_id and target_step_id through store_accessor" do
      company = create(:company)
      workflow = create(:workflow, company: company, name: "Standard Purchase Process")
      step = create(:workflow_step, workflow: workflow, name: "Submit", position: 1)
      log = create(:workflow_step_log, workflow: workflow, workflow_step: step,
        subject: create(:purchase, company: company, name: "Pens restock"))

      log.update!(from_step_id: "step-uuid-1", target_step_id: "step-uuid-2")

      expect(log.metadata["from_step_id"]).to eq("step-uuid-1")
      expect(log.target_step_id).to eq("step-uuid-2")
    end
  end

  describe "polymorphic subject" do
    it "accepts a Purchase as subject" do
      company = create(:company)
      workflow = create(:workflow, company: company, name: "Standard Purchase Process")
      step = create(:workflow_step, workflow: workflow, name: "Submit", position: 1)
      purchase = create(:purchase, company: company, name: "Pens restock")
      log = create(:workflow_step_log, workflow: workflow, workflow_step: step, subject: purchase)

      expect(log.subject).to eq(purchase)
      expect(log.subject_type).to eq("Purchase")
    end
  end
end
