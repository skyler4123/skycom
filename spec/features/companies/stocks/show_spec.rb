# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Stocks stock row", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks") }
  let(:product) { create(:product, company: company, name: "Micro-Controller PCB v2.4") }
  let!(:stock) do
    Stock.create!(company: company, warehouse: warehouse, branch: branch, product: product,
      category: category, property_mapping: category.default_property_mapping,
      name: "Micro-Controller PCB v2.4", code: "SKU-ELEC-9021", quantity: 50, pending: 5,
      price_cents: 1250, property_string_1: "A-01-03")
  end

  before { sign_in(owner) }

  def create_import!(quantity:, code:)
    document = StockImport.create!(company: company, branch: branch, warehouse: warehouse,
      category: category, property_mapping: category.default_property_mapping,
      product: stock.product, code: code, quantity: quantity,
      workflow_status: :pending, business_type: :purchase)
    document.stock_import_stock_appointments.create!(company: company, stock: stock, quantity: quantity)
    StockMovementService::Imports::CreateService.execute!(document: document, employee: nil)
  end

  scenario "shows the row, its quantities, and an empty movement state" do
    visit company_stock_path(company, stock)

    expect(page).to have_content("Micro-Controller PCB v2.4", wait: 10)
    expect(page).to have_content("SKU-ELEC-9021")
    within(find('[data-operation-block="quantities"]')) do
      expect(page).to have_content("$12.50")
      expect(page).to have_content("A-01-03")
      expect(page).to have_content(/On hand/i)
      expect(page).to have_content("50")
      expect(page).to have_content(/Reserved/i)
      expect(page).to have_content("5")
      expect(page).to have_content(/Available/i)
      expect(page).to have_content("45")
      expect(page).to have_content(/Minimum/i)
      expect(page).to have_content("10")
    end
    expect(page).to have_content(/In stock/i)
    expect(page).to have_content("No movements recorded for this stock row.")
    expect(page).to have_link("Open stock list", href: company_stocks_path(company))
    expect(page).to have_link("Open receiving", href: new_company_stock_import_path(company))
    expect(page).to have_link("Open transfer", href: new_company_stock_transfer_path(company))
  end

  scenario "lists a movement with its document code" do
    create_import!(quantity: 12, code: "IMP-SHOW-001")
    visit company_stock_path(company, stock)

    within(find('[data-operation-block="movements"]', wait: 10)) do
      expect(page).to have_content("IMP-SHOW-001")
      expect(page).to have_content("Import")
      expect(page).to have_content("12")
    end
  end
end
