# frozen_string_literal: true

require "rails_helper"

# Failure + recovery loop for Imports: the browser blocks a wrong-header CSV,
# a correct-header but invalid row fails the BE dry run, and re-uploading a
# fixed file passes. The perfect-case journey lives in full_journey_spec.rb.
RSpec.feature "Companies::Imports Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:category) { product_import_category(company: company, name: "Failure Products") }

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

  def setup_import
    import = create(
      :import,
      company: company,
      creator: owner_of(company),
      name: "Failure journey #{SecureRandom.hex(3)}"
    )
    import.update!(
      target_table: "products",
      target_model: "Product",
      category: category
    )
    import
  end

  def csv_file(content)
    file = Tempfile.new([ "products", ".csv" ])
    file.write(content)
    file.rewind
    file
  end

  scenario "blocks wrong headers in the browser, then fails and recovers in the dry run" do
    import = setup_import
    visit company_import_path(company, import)

    expect(page).to have_content("Expected CSV headers", wait: 10)

    # 1) The browser rejects the raw property slot name before uploading.
    wrong_headers = csv_file(
      "name,business_type,property_string_1,Volume (ml)\nSerum,physical,Oily,30\n"
    )
    attach_file("import-file-input", wrong_headers.path)

    expect(page).to have_content("Unknown headers", wait: 10)
    expect(page).to have_content("property_string_1")
    expect(import.reload.source_file).to be_nil

    # 2) Correct headers but an invalid row: the browser accepts, the BE dry run fails.
    invalid_row = csv_file(
      "name,business_type,Skin Type Suitability,Volume (ml)\n,physical,Oily,30\n"
    )
    attach_file("import-file-input", invalid_row.path)

    expect(page).to have_content("Current file", wait: 15)
    click_button "Run dry run"

    expect(page).to have_content("Dry run result", wait: 15)
    expect(page).to have_content("Failed")
    expect(page).to have_content("Name can't be blank")
    expect(page).to have_button("Approve", disabled: true)

    import.reload
    expect(import.dry_run_result["passed"]).to be(false)
    expect(import.dry_run_result["invalid_rows"]).to eq(1)
    expect(import.approvable?).to be(false)

    # 3) Re-upload a fixed file → dry run passes and Approve unlocks.
    fixed = csv_file(product_import_csv)
    attach_file("import-file-input", fixed.path)

    expect(page).to have_content("Current file", wait: 15)
    click_button "Run dry run"

    expect(page).to have_content("Dry run result", wait: 15)
    expect(page).to have_content("Passed")
    expect(page).to have_button("Approve", disabled: false)

    expect(import.reload.approvable?).to be(true)
  end

  scenario "shows a locked setup after approval and offers rollback once completed" do
    import = setup_import
    Imports::DryRunService.call(import: import)
    import.reload.update!(workflow_status: :approved)

    visit company_import_path(company, import)

    expect(page).to have_content("This import is locked.", wait: 10)
    expect(page).not_to have_selector("[data-import-target]")
    expect(page).not_to have_button("Approve")

    import.update!(workflow_status: :completed, completed_at: Time.current)
    visit company_import_path(company, import)

    expect(page).to have_button("Rollback", wait: 10)
  end

  scenario "presents the guided flow with friendly labels instead of DB keys" do
    import = setup_import

    visit company_import_path(company, import)

    expect(page).to have_content("What you're importing", wait: 10)
    expect(page).to have_content("Prepare your file")
    expect(page).to have_content("Upload & check")
    expect(page).to have_content("Review & import")

    target = find("[data-import-target]")
    expect(target).to have_selector("option", text: "Products")
    expect(target).not_to have_selector("option", text: "(products)")

    within("[data-import-columns]", wait: 10) do
      expect(page).to have_content(/what it means/i)
      expect(page).to have_content(/example/i)
      expect(page).to have_content("Text")
      expect(page).not_to have_content("Maps to")
      expect(page).not_to have_content("property slot")
      expect(page).not_to have_content("property_string_1")
    end

    expect(page).to have_button("Download starter CSV")
  end

  scenario "pre-selects the target table and category from index-page params" do
    import = create(
      :import,
      company: company,
      creator: owner_of(company),
      name: "Index prefill #{SecureRandom.hex(3)}"
    )

    visit company_import_path(company, import, target_table: "products", category_id: category.id)

    expect(page).to have_content("What you're importing", wait: 10)
    expect(find("[data-import-target]").value).to eq("products")
    expect(find("[data-import-category]").value).to eq(category.id)
  end
end
