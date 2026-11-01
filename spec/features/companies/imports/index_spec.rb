# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Imports Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)
    seed_client_cache
  end

  def seed_client_cache
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "sidebar shows Imports" do
    visit company_dashboards_path(company)

    expect(page).to have_link("Imports", href: /\/imports$/, visible: :all, wait: 10)
  end

  scenario "lists imports with status and counters" do
    draft = create(:import, company: company, creator: owner_of(company), name: "Products draft #{SecureRandom.hex(3)}")
    completed = create(
      :import,
      company: company,
      creator: owner_of(company),
      name: "Products done #{SecureRandom.hex(3)}",
      target_table: "products",
      target_model: "Product",
      workflow_status: :completed,
      completed_at: Time.current,
      total_rows: 10,
      processed_rows: 10,
      created_rows: 8,
      failed_rows: 2
    )

    visit company_imports_path(company)

    expect(page).to have_content(draft.name, wait: 10)
    expect(page).to have_content(completed.name)
    expect(page).to have_content("8/10")
    expect(page).to have_content("Completed")
    expect(page).to have_content("Draft")
  end

  scenario "creates an import from the modal and lands on its page" do
    visit company_imports_path(company)
    expect(page).to have_css("h2", text: "Imports", wait: 10)
    expect(page).to have_button("New Import", wait: 10)

    name = "Products #{SecureRandom.hex(3)}"
    click_button "New Import"
    expect(page).to have_selector('input[name="import[name]"]', wait: 10)

    fill_in "import[name]", with: name
    click_button "Save Import"

    expect(page).to have_current_path(/imports\/[a-f0-9-]+$/, wait: 10)
    expect(Import.find_by(company: company, name: name)).to be_present
  end

  scenario "shows no delete action for non-draft rows" do
    create(:import, company: company, creator: owner_of(company), name: "Draft #{SecureRandom.hex(3)}")
    create(
      :import,
      company: company,
      creator: owner_of(company),
      name: "Done #{SecureRandom.hex(3)}",
      workflow_status: :completed,
      completed_at: Time.current
    )

    visit company_imports_path(company)

    expect(page).to have_css("tbody tr", count: 2, wait: 10)
    expect(page).to have_button("Delete", count: 1)
  end
end
