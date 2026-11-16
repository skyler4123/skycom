# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::RefundsController", type: :request do
  describe "POST #advance" do
    let(:company) { create(:company) }
    let(:employee) { create(:employee, company: company) }

    let!(:refund_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "refunds") }

    let!(:workflow) do
      Seed::WorkflowService.create(
        company: company, category: refund_category,
        name: "Refunds Process", process_type: :refund_process
      ).tap do |workflow|
        [
          { name: "Submit", position: 1 },
          { name: "Review", position: 2 }
        ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
      end
    end

    let!(:refund) { create(:refund, company: company, category: refund_category, created_by_employee: employee) }

    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = false
      example.run
      ActionController::Base.allow_forgery_protection = original
    end

    before { get sign_in_for_test_path(email: company.user.email) }

    it "advances with approved and moves the pointer" do
      expect {
        post advance_company_refund_path(company, refund), params: { outcome: "approved" }
      }.to change(WorkflowStepLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(refund.reload.workflow_step).to eq(workflow.workflow_steps.find_by(position: 2))
    end

    it "returns 422 for an invalid outcome" do
      post advance_company_refund_path(company, refund), params: { outcome: "hijack" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end

  describe "GET #index" do
    let(:company) { create(:company) }
    before { get sign_in_for_test_path(email: company.user.email) }

    it "returns ok" do
      get company_refunds_path(company)
      expect(response).to have_http_status(:ok)
    end
  end
end
