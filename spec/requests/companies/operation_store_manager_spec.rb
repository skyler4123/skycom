# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::StoreManagerController", type: :request do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Distribution Hub") }
  let!(:operation) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB") }

  before do
    create(
      :stock,
      warehouse: warehouse,
      product: product,
      name: "Micro-Controller PCB v2.4",
      code: "SKU-ELEC-9021"
    ).update!(quantity: 5, pending: 0)
    get sign_in_for_test_path(email: owner.email)
  end

  it "returns the store manager payload for the branch" do
    get store_manager_company_operations_path(company, operation, branch_id: branch.id), as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body.fetch("coming_soon")).to be(false)
    expect(body.fetch("store_manager").fetch("branch")).to eq(
      "id" => branch.id,
      "name" => "Downtown Branch"
    )
    expect(body.fetch("store_manager").fetch("warehouses")).to eq(
      [ { "id" => warehouse.id, "name" => "Central Distribution Hub" } ]
    )
    expect(body.fetch("store_manager").fetch("kpis")).to include("active_skus" => 1)
    expect(body.fetch("store_manager").fetch("stocks")).to include(
      include("code" => "SKU-ELEC-9021", "available" => 5, "status" => "low")
    )
  end

  it "rejects a branch without an active store manager appointment" do
    BranchOperationAppointment.find_by!(operation: operation).update!(workflow_status: :inactive)

    get store_manager_company_operations_path(company, operation, branch_id: branch.id), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body).fetch("errors")).to include("This operation is inactive.")
  end
end
