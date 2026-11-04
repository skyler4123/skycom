# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::OperationConfigs index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

  before do
    Seed::OperationService.seed_defaults!(company: company)
    sign_in(owner)
  end

  scenario "lists company operation configs without an Add button" do
    visit company_operation_configs_path(company)

    expect(page).to have_content("Operation Configs", wait: 10)
    expect(page).to have_content("Operation config overrides every appointment config.")
    expect(page).to have_content("POS")
    expect(page).to have_content("Inventory")
    expect(page).not_to have_link("Add")
  end

  scenario "edits operation metadata and warns about the override" do
    visit company_operation_configs_path(company)

    row = find("tr", text: "POS", wait: 10)
    within(row) { find("button[data-action*='openEditModal']").click }

    expect(page).to have_content("This config is company-wide and overrides every branch/warehouse appointment config.", wait: 10)
    find("textarea[name='metadata']").set('{"roles":["Cashier"]}')
    click_button "Save"

    expect(page).to have_content("Operation config updated.", wait: 10)
    expect(find("tr", text: "POS")).to have_content("Cashier")
  end
end
