# frozen_string_literal: true

require "rails_helper"

# The perfect-case end-to-end journey for Migrations: index → create → upload
# → preview → config → dry run → approve → import → dashboard → rollback,
# asserting UI and DB at every step. Granular specs own the failure branches;
# this one proves the whole user flow works in a real browser.
RSpec.feature "Companies::CompanyMigrations Full Journey", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  before do
    sign_in(owner)
    allow(WEBSOCKET).to receive(:publish_event)

    seed_client_cache(empty_client_data)
  end

  def show_path(migration)
    company_company_migration_path(company, migration)
  end

  def empty_client_data
    JSON.parse(company.to_json).merge(
      "property_mappings" => [], "table_configs" => [], "categories" => [],
      "branches" => [], "departments" => [], "roles" => []
    )
  end

  def full_client_data
    JSON.parse(company.reload.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |record| JSON.parse(record.to_json) },
      "table_configs" => company.table_configs.reset.map { |record| JSON.parse(record.to_json) },
      "categories" => company.categories.reset.map { |record| JSON.parse(record.to_json) },
      "branches" => [], "departments" => [], "roles" => []
    )
  end

  def seed_client_cache(company_data)
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

  scenario "walks the whole import lifecycle" do
    # 1) Index page is alive
    visit company_company_migrations_path(company)
    expect(page).to have_css("h2", text: "Migrations", wait: 10)
    expect(page).to have_button("New Migration")

    # 2) Create through the modal → lands on the show page
    name = "Journey customers #{SecureRandom.hex(3)}"
    click_button "New Migration"
    expect(page).to have_selector('input[name="company_migration[name]"]', wait: 10)
    fill_in "company_migration[name]", with: name
    click_button "Save Migration"

    expect(page).to have_current_path(/company_migrations\/[a-f0-9-]+$/, wait: 10)
    migration = CompanyMigration.find_by!(company: company, name: name)
    expect(migration.workflow_status).to eq("draft")
    expect(migration.folder.parent&.name).to eq("Migrations")

    # 3) Upload customers-10 → chunk recorded, preview rendered
    expect(page).to have_selector("#migration-upload-input", wait: 10)
    attach_file("migration-upload-input", fixture)

    expect(page).to have_content("part-000.csv", wait: 15)
    expect(page).to have_content("Andrew", wait: 10)
    expect(page).to have_content(/customer id/i)

    migration.reload
    expect(migration.total_chunks).to eq(1)
    expect(migration.total_rows).to eq(10)
    expect(migration.ordered_chunks.first.row_count).to eq(10)

    # 4) Save the mapping config — still not approvable without a dry run
    find("[data-config-editor]").set(JSON.pretty_generate(customers_migration_config))
    click_button "Save config"
    expect(page).to have_button("Run dry run", wait: 10)

    migration.reload
    expect(migration.migration_mapping_config["version"]).to eq(1)
    expect(migration.target_resource).to eq("customers")
    expect(migration.dry_run_result).to be_nil
    expect(page).to have_button("Approve", disabled: true)

    # 5) Dry run passes → Approve unlocks
    click_button "Run dry run"
    expect(page).to have_content("Passed", wait: 15)
    expect(page).to have_button("Approve", disabled: false)

    migration.reload
    expect(migration.dry_run_result["passed"]).to be(true)
    expect(migration.dry_run_result["created"]).to eq(10)

    # 6) Approve → status flips and the import job runs (no worker in specs)
    click_button "Approve"
    expect(page).to have_content("Approved", wait: 15)
    expect(migration.reload.workflow_status).to eq("approved")

    CompanyMigrations::ImportJob.perform_now(migration.id)

    visit show_path(migration)
    expect(page).to have_content("Completed", wait: 10)
    expect(page).to have_content("10/10")

    migration.reload
    expect(migration.workflow_status).to eq("completed")
    expect(migration.created_rows).to eq(10)
    expect(migration.failed_rows).to eq(0)
    expect(company.customers.where(external_id: "dE014d010c7ab0c").exists?).to be(true)
    expect(Notification.where(company: company, name: "Migration '#{migration.name}' finished").count).to eq(1)

    # 7) The imported data shows on the Customers dashboard
    imported_category = company.categories.find_by!(name: "Imported Customers", resource_name: "customers")
    seed_client_cache(full_client_data)

    visit company_customers_path(company, category_id: imported_category.id)
    expect(page).to have_selector("tbody tr", wait: 10)
    expect(page).to have_content("Andrew")

    # 8) Rollback → the imported data disappears again
    visit show_path(migration)
    expect(page).to have_button("Rollback", wait: 10)
    click_button "Rollback"
    expect(page).to have_content("Rolling back", wait: 15)
    expect(migration.reload.workflow_status).to eq("rolling_back")

    CompanyMigrations::RollbackJob.perform_now(migration.id)

    visit show_path(migration)
    expect(page).to have_content("Rolled back", wait: 10)

    migration.reload
    expect(migration.workflow_status).to eq("rolled_back")
    expect(company.customers.count).to eq(0)
    expect(Notification.where(company: company, name: "Rollback of '#{migration.name}' completed").count).to eq(1)
  end
end
