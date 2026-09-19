# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::WorkflowsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before { get sign_in_for_test_path(email: owner.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    let!(:workflow) { create(:workflow, company: company) }

    it "returns workflows" do
      get company_workflows_path(company, format: :json)

      names = JSON.parse(response.body)["workflows"].map { |w| w["name"] }
      expect(names).to include(workflow.name)
    end
  end

  describe "POST #create" do
    let(:params) do
      {
        workflow: {
          name: "Expedited Purchase", process_type: "purchase_process", is_default: "true",
          workflow_steps_attributes: {
            "0" => { name: "Submit", position: "1" },
            "1" => { name: "Approve", position: "2" }
          }
        }
      }
    end

    it "creates the workflow with nested steps" do
      expect {
        post company_workflows_path(company), params: params
      }.to change(Workflow, :count).by(1).and change(WorkflowStep, :count).by(2)

      workflow = Workflow.find_by(name: "Expedited Purchase")
      expect(workflow.workflow_steps.map(&:name)).to contain_exactly("Submit", "Approve")
      expect(response).to redirect_to(company_workflow_path(company, workflow))
    end

    it "demotes the previous default of the same process type" do
      old_default = create(:workflow, company: company, process_type: "purchase_process", is_default: true)

      post company_workflows_path(company), params: params

      expect(old_default.reload.is_default).to be false
    end
  end

  describe "PATCH #update" do
    let!(:workflow) do
      create(:workflow, company: company).tap do |workflow|
        Seed::WorkflowStepService.create(company: company, workflow: workflow, name: "Submit", position: 1)
      end
    end

    it "renames the workflow and appends a step" do
      patch company_workflow_path(company, workflow), params: {
        workflow: {
          name: "Renamed Process",
          workflow_steps_attributes: {
            "0" => { id: workflow.workflow_steps.first.id, name: "Submit", position: "1" },
            "1" => { name: "Ship", position: "2" }
          }
        }
      }

      expect(workflow.reload.name).to eq("Renamed Process")
      expect(workflow.workflow_steps.count).to eq(2)
      expect(response).to redirect_to(company_workflow_path(company, workflow))
    end
  end

  describe "DELETE #destroy" do
    let!(:workflow) { create(:workflow, company: company) }
    let!(:purchase) { create(:purchase, company: company, workflow: workflow) }

    it "destroys the workflow and clears purchase pointers" do
      expect {
        delete company_workflow_path(company, workflow)
      }.to change(Workflow, :count).by(-1)

      expect(purchase.reload.current_workflow_step_id).to be_nil
      expect(purchase.reload.workflow_id).to be_nil
    end
  end
end
