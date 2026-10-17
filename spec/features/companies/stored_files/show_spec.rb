require "rails_helper"

RSpec.feature "Companies::StoredFiles Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:folder) { Folder.create!(company: company, name: "Bucket-#{SecureRandom.hex(3)}") }

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

  def create_file(name: "notes-#{SecureRandom.hex(3)}.txt")
    sf = folder.stored_files.build(company: company, name: name)
    sf.file.attach(io: StringIO.new("hello world"), filename: name, content_type: "text/plain")
    sf.save!
    sf
  end

  scenario "shows file metadata with download link" do
    sf = create_file

    visit company_stored_file_path(company, sf)

    expect(page).to have_content(sf.name, wait: 10)
    expect(page).to have_content("txt")
    expect(page).to have_link("Download", href: download_company_stored_file_path(company, sf))
  end

  scenario "deletes the file and returns to the parent folder" do
    sf = create_file

    visit company_stored_file_path(company, sf)
    expect(page).to have_content(sf.name, wait: 10)

    accept_confirm do
      click_button "Delete"
    end

    expect(page).to have_current_path(company_folder_path(company, folder), wait: 10)
    expect(StoredFile.exists?(sf.id)).to be false
  end

  scenario "file card on folder show links to the file show page" do
    sf = create_file

    visit company_folder_path(company, folder)
    expect(page).to have_content(sf.name, wait: 10)

    click_link sf.name

    expect(page).to have_current_path(company_stored_file_path(company, sf), wait: 10)
    expect(page).to have_content(sf.name, wait: 10)
  end

  scenario "file panel fills the remaining page area" do
    sf = create_file

    visit company_stored_file_path(company, sf)
    expect(page).to have_selector("[data-storage-panel]", wait: 10)

    metrics = panel_metrics
    expect(metrics["found"]).to be true
    expect(metrics["widthCoverage"]).to be > 0.9
    expect(metrics["wrapperBottomGap"]).to be <= 40
    expect(metrics["panelBottomGap"]).to be <= 24
  end
end
