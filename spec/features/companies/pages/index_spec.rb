# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Pages index", type: :feature, js: true do
  let(:company) { create(:company, business_type: :retail) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company, name: "Main Branch") }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Main Warehouse") }

  before do
    Seed::PageService.seed_defaults!(company: company)
    sign_in(owner)
  end

  scenario "lists branch and warehouse appointments without an Add button" do
    visit company_pages_path(company)

    expect(page).to have_content("Page Appointments", wait: 10)
    expect(page).to have_content("Appointments connect a page to a branch or warehouse. Page Configs override these values.")
    expect(page).to have_content("POS")
    expect(page).to have_content("Main Branch")
    expect(page).to have_content("Inventory")
    expect(page).to have_content("Main Warehouse")
    expect(page).not_to have_link("Add")
  end

  scenario "edits appointment metadata and status" do
    visit company_pages_path(company)

    row = find("tr", text: "POS", wait: 10)
    within(row) { find("button[data-action*='openEditModal']").click }

    expect(page).to have_content("Appointment config", wait: 10)
    find("textarea[name='metadata']").set('{"layout":{"columns":6}}')
    select "Inactive", from: "workflow_status"
    click_button "Save"

    expect(page).to have_content("Page appointment updated.", wait: 10)
    expect(find("tr", text: "POS")).to have_content("Inactive")
  end

  scenario "launches the POS page with the branch appointment" do
    visit company_pages_path(company)

    within(find("tr", text: "POS", wait: 10)) do
      find("a[href*='/launch']").click
    end

    expect(page).to have_current_path(%r{/companies/#{company.id}/pages/pos/}, wait: 10)
    expect(page).to have_content("Cart is empty", wait: 10)
  end

  scenario "shows a disabled launch when the employee lacks the page role" do
    page_record = company.pages.find_by!(page_type: :pos)
    page_record.update!(metadata: { "roles" => [ "Manager" ] })

    employee_user = create(:user, :company_employee)
    employee = create(:employee, company: company, branch: branch, user: employee_user)
    role = employee.attach_role("Cashier")
    policy = Policy.create!(
      company: company,
      name: "Page read",
      resource: "Page",
      action: "read",
      lifecycle_status: :active,
      workflow_status: :confirmed
    )
    PolicyRoleAppointment.create!(company: company, policy: policy, role: role, workflow_status: :active)

    sign_in(employee_user)
    visit company_pages_path(company)

    row = find("tr", text: "Retail POS", wait: 10)
    expect(row).to have_content("You do not have access to this page.")
    expect(row).not_to have_selector("a[href*='/launch']")
  end
end
