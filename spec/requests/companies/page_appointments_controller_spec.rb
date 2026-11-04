# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Company page appointment updates", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    Seed::PageService.seed_defaults!(company: company)
    get sign_in_for_test_path(email: owner.email)
  end

  describe "PATCH #update for a branch appointment" do
    it "updates metadata and workflow status" do
      appointment = branch.branch_page_appointments.find_by!(page: company.pages.find_by!(page_type: :pos))

      patch company_branch_page_appointment_path(company, appointment), params: {
        branch_page_appointment: {
          metadata: { "layout" => { "columns" => 6 } },
          workflow_status: "inactive"
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("message")).to eq("Page appointment updated.")
      expect(body.fetch("appointment").fetch("workflow_status")).to eq("inactive")
      expect(appointment.reload.metadata).to eq("layout" => { "columns" => 6 })
      expect(appointment).to be_workflow_status_inactive
    end

    it "rejects an unknown workflow status" do
      appointment = branch.branch_page_appointments.first

      patch company_branch_page_appointment_path(company, appointment), params: {
        branch_page_appointment: { workflow_status: "not-a-status" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("errors")).to include("Invalid workflow status")
    end

    it "does not update another company's appointment" do
      other_company = create(:company)
      other_branch = create(:branch, company: other_company)
      Seed::PageService.seed_defaults!(company: other_company)
      other_appointment = other_branch.branch_page_appointments.first

      patch company_branch_page_appointment_path(company, other_appointment), params: {
        branch_page_appointment: { workflow_status: "inactive" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH #update for a warehouse appointment" do
    it "updates metadata and workflow status" do
      appointment = warehouse.page_warehouse_appointments.find_by!(
        page: company.pages.find_by!(page_type: :inventory)
      )

      patch company_page_warehouse_appointment_path(company, appointment), params: {
        page_warehouse_appointment: {
          metadata: { "bin" => "A1" },
          workflow_status: "inactive"
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(appointment.reload.metadata).to eq("bin" => "A1")
      expect(appointment).to be_workflow_status_inactive
    end
  end
end
