# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::Operations::ReceptionController", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:operation_record) do
    create(:operation, company: company, branch: branch, name: "Front Desk", operation_type: :reception)
  end

  before { get sign_in_for_test_path(email: user.email) }

  it "renders the Shell-First mount point" do
    get mobile_company_reception_path(company, operation_record, branch_id: branch.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("companies--operations--reception--show")
    expect(response.body).to include(%(data-company-id="#{company.id}"))
    expect(response.body).to include(%(data-operation-id="#{operation_record.id}"))
  end

  it "redirects when the operation has no active appointment" do
    BranchOperationAppointment.find_by!(operation: operation_record).update!(workflow_status: :inactive)

    get mobile_company_reception_path(company, operation_record, branch_id: branch.id)

    expect(response).to redirect_to(mobile_company_operations_path(company))
    expect(flash[:alert]).to eq("No active operation found for this location.")
  end

  it "returns not found for a non-reception operation" do
    booking = create(:operation, company: company, branch: branch, operation_type: :booking)

    get mobile_company_reception_path(company, booking, branch_id: branch.id)

    expect(response).to have_http_status(:not_found)
  end

  it "does not serve an operation from another company" do
    other_company = create(:company)
    other_branch = create(:branch, company: other_company)
    other_operation = create(:operation, company: other_company, branch: other_branch, operation_type: :reception)

    get mobile_company_reception_path(other_company, other_operation, branch_id: other_branch.id)

    expect(response).to have_http_status(:not_found)
  end
end
