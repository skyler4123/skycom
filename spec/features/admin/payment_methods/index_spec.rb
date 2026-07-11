require "rails_helper"

RSpec.feature "Admin::PaymentMethods", type: :feature, js: true do
  let(:admin) { create(:user, :admin) }
  let(:company_owner) { create(:user, :company_owner) }

  let!(:pm1) { create(:payment_method, name: "Visa Card", code: "VISA", business_type: :b2c, country_code: 840) }
  let!(:pm2) { create(:payment_method, name: "Wire Transfer", code: "WIRE", business_type: :b2b, country_code: 840) }
  let!(:pm3) { create(:payment_method, name: "MoMo Wallet", code: "MOMO", business_type: :b2c, country_code: 704) }

  scenario "admin sees payment methods table with all entries" do
    sign_in(admin)
    visit admin_payment_methods_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Visa Card")
    expect(page).to have_content("Wire Transfer")
    expect(page).to have_content("MoMo Wallet")
  end

  scenario "table shows expected columns" do
    sign_in(admin)
    visit admin_payment_methods_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Name")
    expect(page).to have_selector("th", text: "Code")
    expect(page).to have_selector("th", text: "Type")
    expect(page).to have_selector("th", text: "Country")
    expect(page).to have_selector("th", text: "Status")
    expect(page).to have_selector("th", text: "Created")
  end

  scenario "clicking payment method name navigates to edit page" do
    sign_in(admin)
    visit admin_payment_methods_path

    expect(page).to have_selector("table", wait: 10)
    click_link "Visa Card", match: :first

    expect(page).to have_current_path(edit_admin_payment_method_path(pm1), wait: 10)
  end

  scenario "edit page displays pre-filled form" do
    sign_in(admin)
    visit edit_admin_payment_method_path(pm1)
    expect(page).to have_content("Edit Payment Method", wait: 15)
    expect(page).to have_field("payment_method[name]", with: "Visa Card")
    expect(page).to have_field("payment_method[code]", with: "VISA")
  end

  scenario "admin can update a payment method from edit page" do
    sign_in(admin)
    visit edit_admin_payment_method_path(pm1)

    expect(page).to have_selector("h2", text: "Edit Payment Method", wait: 15)
    fill_in "payment_method[name]", with: "Visa Updated"
    click_button "Save Changes"

    expect(page).to have_current_path(admin_payment_methods_path, wait: 10)
    expect(pm1.reload.name).to eq("Visa Updated")
  end

  scenario "admin can create a new payment method from new page" do
    sign_in(admin)
    visit new_admin_payment_method_path

    expect(page).to have_selector("h2", text: "New Payment Method", wait: 10)
    fill_in "payment_method[name]", with: "Test Pay"
    fill_in "payment_method[code]", with: "TEST_PAY"
    select "B2C", from: "payment_method[business_type]"
    select "US", from: "payment_method[country_code]"
    click_button "Save Payment Method"

    expect(page).to have_current_path(admin_payment_methods_path, wait: 10)
    expect(PaymentMethod.find_by(code: "TEST_PAY")).to be_present
  end

  scenario "non-admin user is redirected to root" do
    sign_in(company_owner)
    visit admin_payment_methods_path

    expect(page).to have_current_path(root_path, wait: 5)
  end
end
