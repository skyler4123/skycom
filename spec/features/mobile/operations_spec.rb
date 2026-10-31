# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Operations", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let!(:page_record) do
    create(
      :page,
      company: company,
      branch: branch,
      name: "Front Counter",
      target_role: :retail_cashier,
      target_resolution: :desktop_widescreen
    )
  end

  scenario "lists every page record for the current company" do
    sign_in(user)
    visit mobile_company_operations_path(company)

    expect(page).to have_css("header h1", text: "Operations")
    expect(page).to have_content("Front Counter")
    expect(page).to have_content(page_record.code)
    expect(page).to have_content("Downtown Branch")
    expect(page).to have_content("Retail")
    expect(page).to have_content("Retail cashier")
    expect(page).to have_content("Desktop widescreen")
    expect(page).to have_content("Active")
    expect(page).to have_content("Approved")
  end

  scenario "does not list another company's pages" do
    other_company = create(:company)
    other_branch = create(:branch, company: other_company, name: "Other Branch")
    other_page = create(
      :page,
      company: other_company,
      branch: other_branch,
      name: "Other Company Page"
    )

    sign_in(user)
    visit mobile_company_operations_path(company)

    expect(page).not_to have_content("Other Company Page")
    expect(page).not_to have_content(other_page.code)
    expect(page).not_to have_content("Other Branch")
  end

  scenario "shows an empty state when the company has no pages" do
    empty_company = create(:company)
    sign_in(empty_company.user)

    visit mobile_company_operations_path(empty_company)

    expect(page).to have_content("No pages yet")
    expect(page).to have_content("Pages created for this company will appear here.")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_operations_path(company)

    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
