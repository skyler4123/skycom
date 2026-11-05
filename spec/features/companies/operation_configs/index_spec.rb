# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::OperationConfigs index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let!(:config_auditor_role) { create(:role, company: company, name: "Config Auditor") }

  before do
    Seed::OperationService.seed_defaults!(company: company)
    sign_in(owner)
  end

  scenario "lists company operation configs without an Add button" do
    visit company_operation_configs_path(company)

    expect(page).to have_content("Operation Configs", wait: 10)
    expect(page).to have_content("Company-wide operation settings. Saving a config here resets every branch and warehouse config.")
    expect(page).to have_content("POS")
    expect(page).to have_content("Inventory")
    expect(page).not_to have_link("Add")
  end

  scenario "filters operation configs by type" do
    visit company_operation_configs_path(company)

    expect(page).to have_select("operation_type", wait: 10)
    select "POS", from: "operation_type"
    click_button "Search"

    expect(page).to have_current_path(/operation_type=pos/, wait: 10)

    within("tbody") do
      expect(page).to have_content("POS")
      expect(page).not_to have_content("Booking")
      expect(page).not_to have_content("Inventory")
    end
  end

  scenario "opens the operation config show page from the row name" do
    visit company_operation_configs_path(company)

    within(find("tr", text: "POS", wait: 10)) { click_link "POS" }

    expect(page).to have_content(/Operation Config/i, wait: 10)
    expect(page).to have_content("Saving config here resets every branch and warehouse config.")
    expect(page).to have_content(/Locations/i)
    expect(page).not_to have_content(/Metadata \(JSON\)/i)
    expect(page).to have_link("Edit Config")
  end

  scenario "edits operation access roles with the role picker and returns to show" do
    operation = company.operations.find_by!(operation_type: :pos)
    operation.update!(metadata: { "roles" => [], "layout" => { "columns" => 6 } })

    visit company_operation_configs_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    expect(page).to have_content("Saving config here resets every branch and warehouse config.", wait: 10)
    expect(page).to have_content("Leave empty to allow every role to use this operation.")
    find("button[aria-haspopup='listbox']").click
    check "Config Auditor"
    find("h2", text: "Edit Config").click
    click_button "Save"

    expect(page).to have_current_path(company_operation_config_path(company, operation), wait: 10)
    expect(page).to have_content("Operation config updated.", wait: 10)
    expect(page).to have_content("Config Auditor", wait: 10)

    operation.reload
    expect(operation.metadata["roles"]).to eq([ "Config Auditor" ])
    expect(operation.metadata["layout"]).to eq({ "columns" => 6 })
  end

  scenario "removes a selected role from the chip list" do
    operation = company.operations.find_by!(operation_type: :pos)
    operation.update!(metadata: { "roles" => [ "Config Auditor" ] })

    visit company_operation_configs_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    find("button[aria-label='Remove Config Auditor']", wait: 10).click
    click_button "Save"

    expect(page).to have_current_path(company_operation_config_path(company, operation), wait: 10)
    expect(page).to have_content("All roles", wait: 10)

    expect(operation.reload.metadata["roles"]).to eq([])
  end

  scenario "clearing every role means every role can use the operation" do
    operation = company.operations.find_by!(operation_type: :pos)
    operation.update!(metadata: { "roles" => [ "Config Auditor" ] })

    visit company_operation_configs_path(company)

    within(find("tr", text: "POS", wait: 10)) { find("a[href$='/edit']").click }

    find("button[aria-haspopup='listbox']", wait: 10).click
    expect(page).to have_checked_field("Config Auditor")
    uncheck "Config Auditor"
    find("button[aria-haspopup='listbox']").click
    click_button "Save"

    expect(page).to have_current_path(company_operation_config_path(company, operation), wait: 10)
    expect(page).to have_content("All roles", wait: 10)

    expect(operation.reload.metadata["roles"]).to eq([])
  end
end
