# frozen_string_literal: true

require "rails_helper"

# The perfect-case end-to-end journey for Imports: index → create → setup →
# sample/header contract → upload → dry run → approve → run → rollback,
# asserting UI and DB at every step. Granular specs own the failure branches.
RSpec.feature "Companies::Imports Full Journey", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:category) { product_import_category(company: company, name: "Journey Products") }

  before do
    sign_in(owner)
    allow(WEBSOCKET).to receive(:publish_event)
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

  def csv_file(content)
    file = Tempfile.new([ "products", ".csv" ])
    file.write(content)
    file.rewind
    file
  end

  scenario "walks the whole import lifecycle" do
    # 1) Index page is alive
    visit company_imports_path(company)
    expect(page).to have_css("h2", text: "Imports", wait: 10)
    expect(page).to have_button("New Import")

    # 2) Create through the modal → lands on the show page
    name = "Journey products #{SecureRandom.hex(3)}"
    click_button "New Import"
    expect(page).to have_selector('input[name="import[name]"]', wait: 10)
    fill_in "import[name]", with: name
    fill_in "import[description]", with: "Q4 catalog"
    click_button "Save Import"

    expect(page).to have_current_path(/imports\/[a-f0-9-]+$/, wait: 10)
    import = Import.find_by!(company: company, name: name)
    expect(import.workflow_status).to eq("draft")
    expect(import.folder.parent&.name).to eq("Imports")

    # 3) Setup: choose products + the category → schema + sample render
    expect(page).to have_selector("[data-import-target]", wait: 10)
    find("[data-import-target]").select("Product (products)")
    find("[data-import-category]").select(category.name)
    click_button "Save setup & load sample"

    expect(page).to have_content("Expected CSV headers", wait: 15)
    expect(page).to have_css("td.font-mono", text: "Skin Type Suitability")
    expect(page).to have_css("td.font-mono", text: "Volume (ml)")
    expect(page).not_to have_css("td.font-mono", text: "property_string_1")

    import.reload
    expect(import.target_table).to eq("products")
    expect(import.target_model).to eq("Product")
    expect(import.category).to eq(category)

    # 4) Upload a correctly-headed CSV
    file = csv_file(product_import_csv)
    attach_file("import-file-input", file.path)

    expect(page).to have_content("Current file", wait: 15)
    import.reload
    expect(import.source_file).to be_present
    expect(import.total_rows).to eq(2)
    expect(import.source_digest).to be_present

    # 5) Dry run passes → Approve unlocks
    click_button "Run dry run"
    expect(page).to have_content("Dry run result", wait: 15)
    expect(page).to have_content("Passed")
    expect(page).to have_button("Approve", disabled: false)

    import.reload
    expect(import.dry_run_result["passed"]).to be(true)
    expect(import.dry_run_result["valid_rows"]).to eq(2)
    expect(import.approvable?).to be(true)

    # 6) Approve → status flips and the job runs (no worker in specs)
    click_button "Approve"
    expect(page).to have_content("Approved", wait: 15)
    expect(import.reload.workflow_status).to eq("approved")

    Imports::RunJob.perform_now(import.id)

    visit company_import_path(company, import)
    expect(page).to have_content("Completed", wait: 10)
    expect(page).to have_content("2/2")

    import.reload
    expect(import.workflow_status).to eq("completed")
    expect(import.created_rows).to eq(2)
    expect(import.failed_rows).to eq(0)

    serum = company.products.find_by!(name: "Imported Serum")
    expect(serum.property_string_1).to eq("Oily")
    expect(serum.property_integer_1).to eq(30)
    expect(serum.category).to eq(category)

    expect(Notification.where(company: company, name: "Import '#{import.name}' finished").count).to eq(1)

    # 7) Rollback → the imported records disappear again
    visit company_import_path(company, import)
    expect(page).to have_button("Rollback", wait: 10)
    click_button "Rollback"
    expect(page).to have_content("Rolling back", wait: 15)
    expect(import.reload.workflow_status).to eq("rolling_back")

    Imports::RollbackJob.perform_now(import.id)

    visit company_import_path(company, import)
    expect(page).to have_content("Rolled back", wait: 10)

    import.reload
    expect(import.workflow_status).to eq("rolled_back")
    expect(import.rolled_back_at).to be_present
    expect(company.products.where(name: [ "Imported Serum", "Imported Cream" ]).count).to eq(0)
    expect(Notification.where(company: company, name: "Rollback of '#{import.name}' completed").count).to eq(1)
  end
end
