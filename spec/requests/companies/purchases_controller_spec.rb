# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PurchasesController", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "purchases" }
    let(:index_class) { Purchase }
    let(:json_key) { "purchases" }
    let(:base_json_path) { "/companies/#{company.id}/purchases.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:purchase, company: company, category: category, **attrs) } }
  end

  describe "POST #advance" do
    let(:company) { create(:company) }
    let(:owner) { company.employees.find_by(business_type: "owner") }
    let(:employee) { create(:employee, company: company) }

    # rails_helper disables company init (Company.skip_init) — seed the category
    # bridge explicitly: the workflow binds to the purchase's category and the
    # purchase auto-binds via Category#default_workflow at creation.
    let!(:purchase_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases") }

    let!(:workflow) do
      Seed::WorkflowService.create(
        company: company, category: purchase_category,
        name: "Office Supplies Purchase Process", process_type: :purchase_process
      ).tap do |workflow|
        [
          { name: "Submit", position: 1 },
          { name: "Manager Approval", position: 2 }
        ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
      end
    end

    let!(:purchase) { create(:purchase, company: company, category: purchase_category, created_by_employee: employee) }

    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = false
      example.run
      ActionController::Base.allow_forgery_protection = original
    end

    before { get sign_in_for_test_path(email: company.user.email) }

    it "advances with approved and moves the pointer (owner)" do
      expect {
        post advance_company_purchase_path(company, purchase), params: { outcome: "approved" }
      }.to change(WorkflowStepLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(purchase.reload.workflow_step).to eq(workflow.workflow_steps.find_by(position: 2))
      expect(purchase.reload.workflow_status_confirmed?).to be true
    end

    it "returns 422 with errors for an invalid outcome" do
      post advance_company_purchase_path(company, purchase), params: { outcome: "hijack" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns 403 for an employee without update permission" do
      get sign_in_for_test_path(email: employee.user.email)

      post advance_company_purchase_path(company, purchase), params: { outcome: "approved" }, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
