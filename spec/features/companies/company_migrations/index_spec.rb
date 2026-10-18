# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::CompanyMigrations Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)

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

  scenario "sidebar shows Data Import" do
    visit company_dashboards_path(company)

    expect(page).to have_link("Data Import", href: /company_migrations/, visible: :all, wait: 10)
  end

  scenario "lists migrations with status and counters" do
    draft = create(:company_migration, company: company, name: "Customers draft #{SecureRandom.hex(3)}")
    completed = create(
      :company_migration,
      company: company,
      name: "Customers done #{SecureRandom.hex(3)}",
      workflow_status: :completed,
      completed_at: Time.current,
      total_chunks: 1,
      total_rows: 10,
      processed_rows: 8,
      created_rows: 8
    )

    visit company_company_migrations_path(company)

    expect(page).to have_content(draft.name, wait: 10)
    expect(page).to have_content(completed.name)
    expect(page).to have_content("8/10")
    expect(page).to have_content("Completed")
    expect(page).to have_content("Draft")
  end

  scenario "creates a migration from the modal and lands on its page" do
    visit company_company_migrations_path(company)
    expect(page).to have_button("New Import", wait: 10)

    name = "Customers import #{SecureRandom.hex(3)}"
    click_button "New Import"
    expect(page).to have_selector('input[name="company_migration[name]"]', wait: 10)

    fill_in "company_migration[name]", with: name
    click_button "Save Import"

    expect(page).to have_current_path(/company_migrations\/[a-f0-9-]+$/, wait: 10)
    expect(CompanyMigration.find_by(company: company, name: name)).to be_present
  end

  scenario "non-draft rows show no delete action while drafts do" do
    draft = create(:company_migration, company: company, name: "Deletable #{SecureRandom.hex(3)}")
    completed = create(
      :company_migration,
      company: company,
      name: "Kept #{SecureRandom.hex(3)}",
      workflow_status: :completed,
      completed_at: Time.current
    )

    visit company_company_migrations_path(company)
    expect(page).to have_content(draft.name, wait: 10)

    within("tr[data-migration-id='#{draft.id}']") do
      expect(page).to have_button("Delete")
    end

    within("tr[data-migration-id='#{completed.id}']") do
      expect(page).to have_no_button("Delete")
    end
  end

  scenario "deletes a draft import with confirmation" do
    draft = create(:company_migration, company: company, name: "To delete #{SecureRandom.hex(3)}")

    visit company_company_migrations_path(company)
    expect(page).to have_content(draft.name, wait: 10)

    within("tr[data-migration-id='#{draft.id}']") do
      accept_confirm do
        click_button "Delete"
      end
    end

    expect(page).to have_no_content(draft.name, wait: 10)
    expect(CompanyMigration.exists?(draft.id)).to be(false)
  end
end
