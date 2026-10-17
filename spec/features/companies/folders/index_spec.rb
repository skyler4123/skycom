require "rails_helper"

RSpec.feature "Companies::Folders Index", type: :feature, js: true do
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

  scenario "lists root buckets with no delete buttons in the grid" do
    Folder.create!(company: company, name: "Bucket-A-#{SecureRandom.hex(3)}")
    Folder.create!(company: company, name: "Bucket-B-#{SecureRandom.hex(3)}")

    visit company_folders_path(company)

    expect(page).to have_content("Bucket-A", wait: 10)
    expect(page).to have_content("Bucket-B")
    expect(page).not_to have_selector("button[data-action*='deleteFolder']")
    expect(page).not_to have_selector("button[data-action*='deleteFile']")
  end

  scenario "clicking a bucket navigates to its show page" do
    bucket = Folder.create!(company: company, name: "Bucket-Nav-#{SecureRandom.hex(3)}")

    visit company_folders_path(company)
    expect(page).to have_content(bucket.name, wait: 10)

    click_link bucket.name

    expect(page).to have_current_path(company_folder_path(company, bucket), wait: 10)
    expect(page).to have_content(bucket.name, wait: 10)
  end

  scenario "sidebar has Storage group with Folders item" do
    visit company_folders_path(company)

    within("aside", visible: :all) do
      expect(page).to have_selector("details[data-sidebar-group='storage']", visible: :all, wait: 10)
      expect(page).to have_link("Folders", href: company_folders_path(company), visible: :all, wait: 10)
    end
  end

  scenario "creates a root folder through the New Folder modal" do
    visit company_folders_path(company)
    expect(page).to have_content("Folders", wait: 10)

    name = "Contracts-#{SecureRandom.hex(3)}"
    click_button "New Folder"
    expect(page).to have_selector('input[name="folder[name]"]', wait: 10)
    fill_in "folder[name]", with: name
    click_button "Save Folder"

    expect(page).to have_content(name, wait: 10)
    expect(Folder.find_by(company: company, name: name, parent_id: nil)).to be_present
  end

  scenario "duplicate folder name keeps the modal open with no new record" do
    existing = Folder.create!(company: company, name: "Dup-#{SecureRandom.hex(3)}")

    visit company_folders_path(company)
    expect(page).to have_content("Folders", wait: 10)

    click_button "New Folder"
    expect(page).to have_selector('input[name="folder[name]"]', wait: 10)
    fill_in "folder[name]", with: existing.name

    expect {
      click_button "Save Folder"
      expect(page).to have_content("has already been taken", wait: 10)
      expect(page).to have_selector('input[name="folder[name]"]')
    }.not_to change(Folder, :count)
  end

  scenario "roots panel fills the remaining page area" do
    visit company_folders_path(company)
    expect(page).to have_selector("[data-storage-panel]", wait: 10)

    metrics = panel_metrics
    expect(metrics["found"]).to be true
    expect(metrics["widthCoverage"]).to be > 0.9
    expect(metrics["wrapperBottomGap"]).to be <= 40
    expect(metrics["panelBottomGap"]).to be <= 24
  end
end
