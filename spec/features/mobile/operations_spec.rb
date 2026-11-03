# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Operations", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let!(:mobile_page) do
    create(
      :page,
      company: company,
      branch: branch,
      target_role: :retail_cashier,
      target_resolution: :mobile
    )
  end
  let!(:desktop_page) do
    create(
      :page,
      company: company,
      branch: branch,
      target_role: :retail_cashier,
      target_resolution: :desktop
    )
  end

  scenario "lists only mobile page records and shows resolution counts" do
    sign_in(user)
    visit mobile_company_operations_path(company)

    expect(page).to have_css("header h1", text: "Operations")
    expect(page).to have_content("Retail POS Mobile")
    expect(page).not_to have_content("Retail POS Desktop")
    expect(page).to have_content(mobile_page.code)
    expect(page).to have_content("Downtown Branch")
    expect(page).to have_content("Retail")
    expect(page).to have_content("Retail cashier")
    expect(page).to have_content("Mobile")
    expect(page).to have_content("Active")
    expect(page).to have_content("Approved")

    summary = find("[data-pages-summary]")
    expect(summary).to have_content("2")
    expect(summary).to have_content("1")
  end

  scenario "opens the coming soon screen from a mobile page" do
    sign_in(user)
    visit mobile_company_operations_path(company)

    find("a[href='#{mobile_company_page_path(company, mobile_page)}']").click

    expect(page).to have_content(/coming soon/i)
    expect(page).to have_content("Retail POS Mobile")
    expect(page).to have_link("Back to Operations")
  end

  scenario "does not list another company's pages" do
    other_company = create(:company, business_type: :retail)
    other_branch = create(:branch, company: other_company, name: "Other Branch")
    other_page = create(
      :page,
      company: other_company,
      branch: other_branch,
      target_role: :retail_cashier,
      target_resolution: :mobile
    )

    sign_in(user)
    visit mobile_company_operations_path(company)

    expect(page).not_to have_content("Other Company Page")
    expect(page).not_to have_content(other_page.code)
    expect(page).not_to have_content("Other Branch")
  end

  scenario "shows an empty state when the company has no pages" do
    empty_company = create(:company, business_type: :retail)
    sign_in(empty_company.user)

    visit mobile_company_operations_path(empty_company)

    expect(page).to have_content("No pages yet")
    expect(page).to have_content("Pages created for this company will appear here.")
  end

  scenario "redirects an employee without Page read to home" do
    member_user = create(:user)
    create(:employee, user: member_user, company: company)

    sign_in(member_user)
    visit mobile_company_operations_path(company)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end

  scenario "protects page detail with the same Page read grant" do
    member_user = create(:user)
    create(:employee, user: member_user, company: company)

    sign_in(member_user)
    visit mobile_company_page_path(company, mobile_page)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_operations_path(company)

    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
