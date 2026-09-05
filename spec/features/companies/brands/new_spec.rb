require "rails_helper"

RSpec.feature "Companies::Brands New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

before do
  sign_in(owner)
  seed_full_client_cache(company: company, user: owner)
end

  scenario "renders new brand form with name and type fields" do
    visit new_company_brand_path(company)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    expect(page).to have_selector('select[name="brand[business_type]"]', wait: 10)
  end

  scenario "creates brand and redirects to show page" do
    visit new_company_brand_path(company)

    fill_in 'brand[name]', with: 'New Test Brand'
    select 'Manufacturer', from: 'brand[business_type]'

    click_button "Save Brand"

    expect(page).to have_content('New Test Brand', wait: 10)

    brand_record = Brand.find_by(name: "New Test Brand")
    expect(brand_record).to be_present
    expect(page).to have_current_path(company_brand_path(company, brand_record), wait: 10)
  end

  scenario "creates brand with email" do
    visit new_company_brand_path(company)

    fill_in 'brand[name]', with: 'Brand With Email'
    fill_in 'brand[email]', with: 'brand@example.com'

    click_button "Save Brand"

    expect(page).to have_content('Brand With Email', wait: 10)

    brand_record = Brand.find_by(name: "Brand With Email")
    expect(brand_record).to be_present
    expect(brand_record.email).to eq('brand@example.com')
  end
end
