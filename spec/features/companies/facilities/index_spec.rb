require "rails_helper"

RSpec.feature "Companies::Facilities Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  let!(:facility) { create(:facility, company: company, branch: branch) }

  before do
    sign_in(owner)
  end

  scenario "index page loads and displays facilities table" do
    visit company_facilities_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_selector('thead th', minimum: 2)
    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(facility.name)
  end

  scenario "edit button links to edit page for facility" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    click_link facility.name, match: :first
    expect(page).to have_current_path(/facilities\/#{facility.id}$/, wait: 10)
    expect(page).to have_content(facility.name)
  end

  scenario "displays facility workflow status as badge" do
    visit company_facilities_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
