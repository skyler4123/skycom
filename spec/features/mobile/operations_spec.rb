# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Operations", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let!(:operation_record) do
    create(
      :operation,
      company: company,
      branch: branch,
      name: "Front Counter",
      operation_type: :pos
    )
  end

  scenario "lists every accessible operation for the current company" do
    sign_in(user)
    visit mobile_company_operations_path(company)

    expect(page).to have_css("header h1", text: "Operations")
    expect(page).to have_content("Front Counter")
    expect(page).to have_content(operation_record.code)
    expect(page).to have_content("Downtown Branch")
    expect(page).to have_content("POS")
    expect(page).to have_content("Active")
    expect(page).to have_content("Approved")
    expect(page).not_to have_content("Retail cashier")
  end

  scenario "does not list another company's operations" do
    other_company = create(:company)
    other_branch = create(:branch, company: other_company, name: "Other Branch")
    other_operation = create(:operation, company: other_company, branch: other_branch, name: "Other Company Operation")

    sign_in(user)
    visit mobile_company_operations_path(company)

    expect(page).not_to have_content("Other Company Operation")
    expect(page).not_to have_content(other_operation.code)
    expect(page).not_to have_content("Other Branch")
  end

  scenario "shows an empty state when the company has no operations" do
    empty_company = create(:company)
    sign_in(empty_company.user)

    visit mobile_company_operations_path(empty_company)

    expect(page).to have_content("No operations yet")
    expect(page).to have_content("Add a branch or warehouse to start using operations.")
  end

  scenario "redirects an employee without Operation read to home" do
    member_user = create(:user)
    create(:employee, user: member_user, company: company)

    sign_in(member_user)
    visit mobile_company_operations_path(company)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_operations_path(company)

    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
