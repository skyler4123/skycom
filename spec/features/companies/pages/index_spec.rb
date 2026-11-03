# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Pages Index", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }

  let!(:cashier_desktop) do
    create(:page, company: company, branch: branch, target_role: :retail_cashier, target_resolution: :desktop)
  end
  let!(:cashier_mobile) do
    create(:page, company: company, branch: branch, target_role: :retail_cashier, target_resolution: :mobile)
  end
  let!(:manager_desktop) do
    create(:page, company: company, branch: branch, target_role: :retail_store_manager, target_resolution: :desktop)
  end
  let!(:manager_mobile) do
    create(:page, company: company, branch: branch, target_role: :retail_store_manager, target_resolution: :mobile)
  end

  before { sign_in(owner) }

  scenario "shows resolution counts and only desktop pages" do
    visit company_pages_path(company)

    expect(page).to have_content("Total Pages", wait: 10)
    expect(page).to have_content("Retail POS Desktop")
    expect(page).to have_content("Retail Store Manager Desktop")
    expect(page).not_to have_content("Retail POS Mobile")
    expect(page).not_to have_content("Retail Store Manager Mobile")

    summary = find("[data-pages-summary]")
    expect(summary).to have_content("4")
    expect(summary).to have_content("2")
  end

  scenario "opens the coming soon screen from a placeholder page" do
    visit company_pages_path(company)

    find("a[href='#{launch_company_page_path(company, manager_desktop)}']", wait: 10).click

    expect(page).to have_content(/coming soon/i, wait: 10)
    expect(page).to have_content("Retail Store Manager Desktop")
    expect(page).to have_link("Back to Pages")
  end

  scenario "links the implemented desktop cashier page to its POS screen" do
    visit company_pages_path(company)

    link = find("a[href='#{launch_company_page_path(company, cashier_desktop)}']", wait: 10)

    expect(link).to be_present
  end

  scenario "new page form offers only the company's catalog and two resolutions" do
    visit new_company_page_path(company)

    expect(page).to have_select(
      "page[target_role]",
      with_options: [ "Retail POS", "Retail Store Manager" ],
      wait: 10
    )
    expect(page).to have_select(
      "page[target_resolution]",
      with_options: [ "Mobile", "Desktop" ],
      wait: 10
    )
    expect(page).not_to have_content("Restaurant POS")
  end
end
