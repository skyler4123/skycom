require "rails_helper"

RSpec.feature "Companies::Purchases New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:purchase_item) { create(:purchase_item, company: company, name: "Ballpoint Pen", estimated_unit_price: 2.50) }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders new purchase form with base fields" do
    visit new_company_purchase_path(company)

    expect(page).to have_selector('input[name="purchase[name]"]', wait: 10)
    expect(page).to have_selector('select[name="purchase[business_type]"]', wait: 10)
    expect(page).to have_selector('select[name="purchase[currency]"]', wait: 10)
    expect(page).to have_selector('input[name="purchase[needed_by]"]', wait: 10)
    expect(page).to have_selector('select[name="purchase[supplier_id]"]', wait: 10)
  end

  scenario "add item renders a line item row" do
    visit new_company_purchase_path(company)
    expect(page).to have_selector('input[name="purchase[name]"]', wait: 10)

    click_button "Add Item"

    expect(page).to have_selector('select[name="purchase[purchase_item_appointments_attributes][0][purchase_item_id]"]', wait: 10)
    expect(page).to have_selector('input[name="purchase[purchase_item_appointments_attributes][0][quantity]"]', wait: 10)
    expect(page).to have_selector('input[name="purchase[purchase_item_appointments_attributes][0][unit_price]"]', wait: 10)
  end

  scenario "creates purchase with line item and redirects to show page" do
    visit new_company_purchase_path(company)
    expect(page).to have_selector('input[name="purchase[name]"]', wait: 10)

    fill_in 'purchase[name]', with: 'Marker pens restock'
    click_button "Add Item"
    select 'Ballpoint Pen', from: 'purchase[purchase_item_appointments_attributes][0][purchase_item_id]'
    fill_in 'purchase[purchase_item_appointments_attributes][0][quantity]', with: '5'
    fill_in 'purchase[purchase_item_appointments_attributes][0][unit_price]', with: '2.50'

    click_button "Save Purchase"

    purchase_record = Purchase.find_by(name: "Marker pens restock")
    expect(purchase_record).to be_present
    expect(page).to have_current_path(company_purchase_path(company, purchase_record), wait: 10)
    expect(page).to have_content('Marker pens restock', wait: 10)

    expect(purchase_record.purchase_item_appointments.count).to eq(1)
    appointment = purchase_record.purchase_item_appointments.first
    expect(appointment.quantity).to eq(5)
    expect(appointment.unit_price.to_f).to eq(2.50)
    expect(appointment.total_price.to_f).to eq(12.50)
  end
end
