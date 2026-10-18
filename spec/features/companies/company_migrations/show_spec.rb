# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::CompanyMigrations Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  before do
    sign_in(owner)
    allow(WEBSOCKET).to receive(:publish_event)

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

  def show_path(migration)
    company_company_migration_path(company, migration)
  end

  scenario "uploads a BOM-prefixed customers-10 as one chunk and renders the preview" do
    migration = create(:company_migration, company: company)

    tempfile = Tempfile.new([ "customers10-bom", ".csv" ])
    tempfile.binmode
    tempfile.write("\uFEFF#{File.read(fixture)}")
    tempfile.rewind

    visit show_path(migration)
    expect(page).to have_selector("#migration-upload-input", wait: 10)

    attach_file("migration-upload-input", tempfile.path)

    expect(page).to have_content("part-000.csv", wait: 15)

    migration.reload
    expect(migration.ordered_chunks.size).to eq(1)
    expect(migration.ordered_chunks.first.row_count).to eq(10)
    expect(migration.source_header).not_to include("\uFEFF")

    expect(page).to have_content("Andrew", wait: 10)
    expect(page).to have_content(/customer id/i)
  ensure
    tempfile&.close!
  end

  scenario "splits customers-1000 into multiple chunks under the limit" do
    stub_const("MIGRATION_CHUNK_MAX_BYTES", 32.kilobytes)
    migration = create(:company_migration, company: company)

    visit show_path(migration)
    expect(page).to have_selector("#migration-upload-input", wait: 10)

    attach_file("migration-upload-input", Rails.root.join("faker/files/customers-1000.csv"))

    expect(page).to have_content("part-000.csv", wait: 30)

    migration.reload
    chunks = migration.ordered_chunks
    expect(chunks.size).to be > 1
    expect(chunks.size).to eq(migration.total_chunks)
    expect(chunks.sum(&:row_count)).to eq(1000)
    expect(migration.total_rows).to eq(1000)

    headers = chunks.map { |chunk| chunk.file.download.lines.first.sub(/\A\uFEFF/, "").strip }
    expect(headers.uniq.size).to eq(1)
    expect(headers.first).to include("Customer Id")
  end

  scenario "dry run passes with the normative config and enables Approve" do
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: {})

    visit show_path(migration)
    expect(page).to have_selector("[data-config-editor]", wait: 10)

    find("[data-config-editor]").set(JSON.pretty_generate(customers_migration_config))
    click_button "Save config"
    expect(page).to have_button("Run dry run", wait: 10)

    click_button "Run dry run"

    expect(page).to have_content("Passed", wait: 15)
    expect(page).to have_button("Approve", disabled: false)
  end

  scenario "editing the config after a pass disables Approve again" do
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
    migration.update!(dry_run_result: { "passed" => true, "config_digest" => migration.config.digest })

    visit show_path(migration)
    expect(page).to have_button("Approve", disabled: false, wait: 10)

    edited = customers_migration_config
    edited["targets"][0]["columns"]["Last Name"] = { "target" => "description" }
    find("[data-config-editor]").set(JSON.pretty_generate(edited))
    click_button "Save config"

    expect(page).to have_button("Approve", disabled: true, wait: 10)
  end

  scenario "approve enqueues and shows completed counters after the job runs" do
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
    migration.update!(dry_run_result: { "passed" => true, "config_digest" => migration.config.digest })

    visit show_path(migration)
    expect(page).to have_button("Approve", disabled: false, wait: 10)

    click_button "Approve"
    expect(page).to have_content("Approved", wait: 15)

    migration.reload
    expect(migration.workflow_status).to eq("approved")

    CompanyMigrations::ImportJob.perform_now(migration.id)
    visit show_path(migration)

    expect(page).to have_content("Completed", wait: 10)
    expect(page).to have_content("10/10")
  end

  scenario "rollback button appears for a completed migration and queues the rollback" do
    migration = create(
      :company_migration,
      company: company,
      workflow_status: :completed,
      completed_at: Time.current,
      total_chunks: 1,
      total_rows: 10,
      processed_rows: 10
    )

    visit show_path(migration)
    expect(page).to have_button("Rollback", wait: 10)

    click_button "Rollback"

    expect(page).to have_content("Rolling back", wait: 15)
    expect(migration.reload.workflow_status).to eq("rolling_back")
  end
end
