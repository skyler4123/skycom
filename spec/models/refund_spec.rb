require "rails_helper"

RSpec.describe Refund, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:customer).optional }
    it { should belong_to(:order).optional }
    it { should belong_to(:invoice).optional }
    it { should belong_to(:source_transaction).optional }
    it { should belong_to(:payment_method).optional }
    it { should belong_to(:product).optional }
    it { should belong_to(:workflow_step).optional }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
    it { should have_many(:workflow_step_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:refund_type).with_values(cash: 0, product: 1, service: 2, credit: 3) }
  end

  it "binds a workflow when category has one" do
    company = create(:company)
    category = Category.find_or_create_by!(company: company, resource_name: "refunds") { |c| c.name = "Refunds" }
    workflow = Workflow.create!(company: company, category: category, name: "Refunds Process", process_type: :refund_process)
    WorkflowStep.create!(company: company, workflow: workflow, name: "Submit", position: 1)
    refund = create(:refund, company: company, category: category)
    expect(refund.workflow_step).to be_present
    expect(refund.workflow_status).to eq("pending")
  end
end