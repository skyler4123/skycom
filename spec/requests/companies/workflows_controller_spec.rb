# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::WorkflowsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases") }

  before { get sign_in_for_test_path(email: owner.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    let!(:workflow) { create(:workflow, company: company, category: category) }

    it "returns workflows with their category" do
      get company_workflows_path(company, format: :json)

      payload = JSON.parse(response.body)["workflows"].find { |w| w["name"] == workflow.name }
      expect(payload["category"]["id"]).to eq(category.id)
    end
  end

  describe "POST #create" do
    let(:params) do
      {
        workflow: {
          name: "Expedited Purchase", process_type: "purchase_process", category_id: category.id,
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
      expect(workflow.category_id).to eq(category.id)
      expect(response).to redirect_to(company_workflow_path(company, workflow))
    end

    it "rejects a category from another company" do
      other_category = Seed::CategoryService.find_or_create_for(
        company: create(:company), resource_name: "purchases"
      )

      expect {
        post company_workflows_path(company), params: params.deep_merge(
          workflow: { category_id: other_category.id }
        )
      }.to change(Workflow, :count).by(0)
    end
  end

  describe "PATCH #update" do
    let!(:workflow) do
      create(:workflow, company: company, category: category).tap do |workflow|
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
    let!(:workflow) do
      create(:workflow, company: company, category: category).tap do |workflow|
        Seed::WorkflowStepService.create(company: company, workflow: workflow, name: "Submit", position: 1)
      end
    end
    let!(:purchase) { create(:purchase, company: company, category: category) }

    it "destroys the workflow and clears purchase pointers" do
      expect(purchase.workflow_step).to be_present

      expect {
        delete company_workflow_path(company, workflow)
      }.to change(Workflow, :count).by(-1)

      expect(purchase.reload.workflow_step_id).to be_nil
    end
  end
end
