# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::StoreManager", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Distribution Hub") }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let(:store_manager_path) do
    "/companies/#{company.id}/operations/store_manager/#{operation_record.id}?branch_id=#{branch.id}"
  end
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB v2.4") }

  let!(:low_stock) do
    Stock.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: 5,
      pending: 0,
      name: "Micro-Controller PCB v2.4",
      code: "SKU-ELEC-9021",
      business_type: :inventory,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  let!(:inbound) do
    StockImport.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: 40,
      name: "Apex Silicon Ltd",
      code: "STKIM-STORE",
      business_type: :purchase,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
  end

  before { sign_in(owner) }

  scenario "renders the real stock, inbound and outbound data" do
    StockExport.create!(
      company: company,
      branch: branch,
      warehouse: warehouse,
      product: product,
      quantity: 12,
      name: "Regional Retail Hub #04",
      code: "STKEX-STORE",
      business_type: :sale,
      lifecycle_status: :active,
      workflow_status: :confirmed
    )

    visit store_manager_path

    expect(page).to have_content("Store Manager Console", wait: 10)
    expect(page).to have_content("Downtown Branch")
    expect(page).to have_content("Central Distribution Hub")

    expect(page).to have_content("On-Hand Stock")
    expect(page).to have_content("Micro-Controller PCB v2.4")
    expect(page).to have_content("SKU-ELEC-9021")

    expect(page).to have_content("Inbound")
    expect(page).to have_content("Apex Silicon Ltd")
    expect(page).to have_content("STKIM-STORE")

    expect(page).to have_content("Outbound")
    expect(page).to have_content("Regional Retail Hub #04")
    expect(page).to have_content("STKEX-STORE")

    expect(page).to have_css("[data-store-manager-stock]", text: "Micro-Controller PCB v2.4")
    expect(page).to have_css("[data-store-manager-inbound]", text: "Apex Silicon Ltd")
    expect(page).to have_css("[data-store-manager-outbound]", text: "Regional Retail Hub #04")
  end

  scenario "shows the empty state when the branch has no stock documents" do
    inbound.destroy!
    low_stock.destroy!

    visit store_manager_path

    expect(page).to have_content("Store Manager Console", wait: 10)
    expect(page).to have_content("No stock records for this branch yet.")
    expect(page).to have_content("No inbound shipments.")
    expect(page).to have_content("No outbound orders.")
  end
end
