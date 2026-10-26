require "rails_helper"

RSpec.describe Ticket, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:assigned_employee).optional }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping).optional }
    it { should belong_to(:workflow_step).optional }
    it { should have_many(:ticket_comments).dependent(:destroy) }
    it { should have_many(:ticket_logs).dependent(:destroy) }
    it { should have_many(:workflow_step_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_presence_of(:priority) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:priority) }
  end

  describe "workflow auto-binding on create" do
    let(:company) { create(:company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets") }
    let(:category_workflow) do
      Seed::WorkflowService.create(
        company: company, category: category, name: "Standard Ticket Process",
        process_type: :ticket_process
      )
    end

    before do
      category_workflow
      Seed::WorkflowStepService.create(company: company, workflow: category_workflow, name: "To Do", position: 1)
      Seed::WorkflowStepService.create(company: company, workflow: category_workflow, name: "In Progress", position: 2)
    end

    it "binds the category's workflow and starts pending" do
      ticket = create(:ticket, company: company, category: category, name: "Fix printer")

      expect(ticket.workflow_step).to eq(category_workflow.workflow_steps.order(:position).first)
      expect(ticket.workflow_step.workflow).to eq(category_workflow)
      expect(ticket.reload.workflow_status_pending?).to be true
    end

    it "writes a submitted WorkflowStepLog for the creator" do
      employee = create(:employee, company: company)
      ticket = create(:ticket, company: company, category: category, name: "Fix printer", created_by_employee: employee, employee: employee)

      log = ticket.workflow_step_logs.sole
      expect(log.outcome_submitted?).to be true
      expect(log.employee_id).to eq(employee.id)
    end

    it "stays draft when binding is skipped" do
      ticket = create(:ticket, company: company, category: category, name: "Fix printer", skip_workflow: true)
      expect(ticket.workflow_step).to be_nil
      expect(ticket.reload.workflow_status_draft?).to be true
    end

    it "stays draft when the category has no workflow" do
      category_without_workflow = create(:category, company: company, name: "Misc", resource_name: "tickets")
      ticket = create(:ticket, company: company, category: category_without_workflow, name: "Fix printer")
      expect(ticket.category.default_workflow).to be_nil
      expect(ticket.workflow_step).to be_nil
      expect(ticket.reload.workflow_status_draft?).to be true
      expect(ticket.workflow_step_logs.count).to eq(0)
    end
  end

  it "creates a TicketLog on create" do
    company = create(:company)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets")
    ticket = create(:ticket, company: company, category: category, name: "Fix printer")
    expect(ticket.ticket_logs.count).to be >= 1
  end
end
