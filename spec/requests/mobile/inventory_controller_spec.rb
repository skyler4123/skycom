# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::Operations::InventoryController", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let!(:operation_record) { create(:operation, company: company, operation_type: :inventory) }
  let!(:appointment) do
    create(:operation_warehouse_appointment, company: company, operation: operation_record, warehouse: warehouse)
  end

  before { get sign_in_for_test_path(email: user.email) }

  it "renders the Shell-First mount point" do
    get mobile_company_inventory_path(company, operation_record, warehouse_id: warehouse.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("companies--operations--inventory--show")
    expect(response.body).to include(%(data-company-id="#{company.id}"))
    expect(response.body).to include(%(data-operation-id="#{operation_record.id}"))
  end

  it "redirects when the operation has no active appointment" do
    appointment.update!(workflow_status: :inactive)

    get mobile_company_inventory_path(company, operation_record, warehouse_id: warehouse.id)

    expect(response).to redirect_to(mobile_company_operations_path(company))
    expect(flash[:alert]).to eq("No active operation found for this location.")
  end

  it "returns not found for a non-inventory operation" do
    pos = create(:operation, company: company, branch: branch, operation_type: :pos)

    get mobile_company_inventory_path(company, pos, warehouse_id: warehouse.id)

    expect(response).to have_http_status(:not_found)
  end

  it "does not serve an operation from another company" do
    other_company = create(:company)
    other_branch = create(:branch, company: other_company)
    other_warehouse = create(:warehouse, company: other_company, branch: other_branch)
    other_operation = create(:operation, company: other_company, operation_type: :inventory)

    get mobile_company_inventory_path(other_company, other_operation, warehouse_id: other_warehouse.id)

    expect(response).to have_http_status(:not_found)
  end
end
