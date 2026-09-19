require "rails_helper"

RSpec.feature "Companies::Purchases Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:purchase_item) { create(:purchase_item, company: company, name: "Ballpoint Pen", estimated_unit_price: 2.50) }
  let!(:other_item) { create(:purchase_item, company: company, name: "Stapler") }
  let!(:purchase) { create(:purchase, company: company, name: "Pens restock") }
  let!(:appointment) do
    Seed::PurchaseItemAppointmentService.create(
      company: company, purchase: purchase, purchase_item: purchase_item,
      quantity: 5, unit_price: 2.50
    )
  end

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

  scenario "renders prefilled edit form" do
    visit edit_company_purchase_path(company, purchase)

    expect(page).to have_selector('input[name="purchase[name]"]', wait: 10)
    expect(find('input[name="purchase[name]"]').value).to eq('Pens restock')
    expect(page).to have_selector('select[name="purchase[purchase_item_appointments_attributes][0][purchase_item_id]"]', wait: 10)
  end

  scenario "renames the purchase and redirects to show page" do
    visit edit_company_purchase_path(company, purchase)
    expect(page).to have_selector('input[name="purchase[name]"]', wait: 10)

    fill_in 'purchase[name]', with: 'Pens restock updated'
    click_button "Save Changes"

    expect(page).to have_current_path(company_purchase_path(company, purchase), wait: 10)
    expect(page).to have_content('Pens restock updated', wait: 10)

    expect(purchase.reload.name).to eq('Pens restock updated')
  end

  scenario "adds a line item on edit" do
    visit edit_company_purchase_path(company, purchase)
    expect(page).to have_selector('input[name="purchase[name]"]', wait: 10)

    click_button "Add Item"
    select 'Stapler', from: 'purchase[purchase_item_appointments_attributes][1][purchase_item_id]'
    fill_in 'purchase[purchase_item_appointments_attributes][1][quantity]', with: '2'
    fill_in 'purchase[purchase_item_appointments_attributes][1][unit_price]', with: '10.00'
    click_button "Save Changes"

    expect(page).to have_current_path(company_purchase_path(company, purchase), wait: 10)

    expect(purchase.reload.purchase_item_appointments.count).to eq(2)
    new_appointment = purchase.purchase_item_appointments.find_by(purchase_item_id: other_item.id)
    expect(new_appointment).to be_present
    expect(new_appointment.total_price.to_f).to eq(20.00)
  end
end
