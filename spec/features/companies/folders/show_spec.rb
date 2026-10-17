require "rails_helper"

RSpec.feature "Companies::Folders Show", type: :feature, js: true do
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

  scenario "shows folder detail with breadcrumb, children and files" do
    parent = Folder.create!(company: company, name: "Parent-#{SecureRandom.hex(3)}")
    child = Folder.create!(company: company, name: "Child-#{SecureRandom.hex(3)}", parent: parent)
    sf = parent.stored_files.build(company: company, name: "doc-#{SecureRandom.hex(3)}.pdf")
    sf.file.attach(io: StringIO.new("pdfdata"), filename: "doc.pdf", content_type: "application/pdf")
    sf.save!

    visit company_folder_path(company, parent)

    expect(page).to have_content(parent.name, wait: 10)
    expect(page).to have_link("Home", href: company_folders_path(company))
    expect(page).to have_content(child.name)
    expect(page).to have_content(sf.name)
  end

  scenario "uploads a real faker file inside the folder" do
    parent = Folder.create!(company: company, name: "Upload-#{SecureRandom.hex(3)}")

    visit company_folder_path(company, parent)
    expect(page).to have_content(parent.name, wait: 10)

    attach_file "file", Rails.root.join("faker/files/Untitled document.txt")
    click_button "Upload Files"

    expect(page).to have_content("Untitled document.txt", wait: 10)
    created = StoredFile.find_by(folder: parent, name: "Untitled document.txt")
    expect(created).to be_present
    expect(created.file_size).to be > 0
  end

  scenario "deletes an empty folder and returns to the index" do
    parent = Folder.create!(company: company, name: "Gone-#{SecureRandom.hex(3)}")

    visit company_folder_path(company, parent)
    expect(page).to have_content(parent.name, wait: 10)

    accept_confirm do
      click_button "Delete"
    end

    expect(page).to have_current_path(company_folders_path(company), wait: 10)
    expect(Folder.exists?(parent.id)).to be false
  end

  scenario "blocks delete of a non-empty folder" do
    parent = Folder.create!(company: company, name: "Keeper-#{SecureRandom.hex(3)}")
    Folder.create!(company: company, name: "Child-#{SecureRandom.hex(3)}", parent: parent)

    visit company_folder_path(company, parent)
    expect(page).to have_content(parent.name, wait: 10)

    accept_confirm do
      click_button "Delete"
    end

    expect(page).to have_content("not empty", wait: 10)
    expect(page).to have_current_path(company_folder_path(company, parent), wait: 10)
    expect(page).to have_content(parent.name)
    expect(Folder.exists?(parent.id)).to be true
  end

  scenario "creates a child folder through the modal with correct parent" do
    parent = Folder.create!(company: company, name: "Parent-#{SecureRandom.hex(3)}")

    visit company_folder_path(company, parent)
    expect(page).to have_content(parent.name, wait: 10)

    name = "Nested-#{SecureRandom.hex(3)}"
    click_button "New Folder"
    expect(page).to have_selector('input[name="folder[name]"]', wait: 10)
    fill_in "folder[name]", with: name
    click_button "Save Folder"

    expect(page).to have_content(name, wait: 10)
    child = Folder.find_by(company: company, name: name)
    expect(child).to be_present
    expect(child.parent_id).to eq(parent.id)
  end

  scenario "oversize upload creates nothing and stays on the page" do
    parent = Folder.create!(company: company, name: "Capped-#{SecureRandom.hex(3)}")
    big = Tempfile.new([ "big", ".txt" ])
    big.binmode
    big.write("a" * (STORED_FILE_MAX_SIZES_BY_TYPE[:text] + 1))
    big.flush
    big.rewind
    big_path = big.path
    # Tempfile without .txt suffix would fail extension sniffing; rename to keep it real
    txt_path = "#{big_path}.txt"
    FileUtils.mv(big_path, txt_path)

    visit company_folder_path(company, parent)
    expect(page).to have_content(parent.name, wait: 10)

    expect {
      attach_file "file", txt_path
      click_button "Upload Files"
      expect(page).to have_content("too big", wait: 10)
      expect(page).to have_content(parent.name)
    }.not_to change(StoredFile, :count)
  ensure
    FileUtils.rm_f(txt_path)
  end

  scenario "disallowed file type upload creates nothing" do
    parent = Folder.create!(company: company, name: "Strict-#{SecureRandom.hex(3)}")
    sh = Tempfile.new([ "run", ".sh" ])
    sh.write("#!/bin/sh\necho hi")
    sh.flush
    sh.rewind
    sh_path = sh.path
    sh_bin = "#{sh_path}.sh"
    FileUtils.mv(sh_path, sh_bin)

    visit company_folder_path(company, parent)
    expect(page).to have_content(parent.name, wait: 10)

    expect {
      attach_file "file", sh_bin
      click_button "Upload Files"
      expect(page).to have_content("is not allowed", wait: 10)
      expect(page).to have_content(parent.name)
    }.not_to change(StoredFile, :count)
  ensure
    FileUtils.rm_f(sh_bin)
  end

  scenario "folder panel fills the remaining page area" do
    parent = Folder.create!(company: company, name: "Filler-#{SecureRandom.hex(3)}")

    visit company_folder_path(company, parent)
    expect(page).to have_selector("[data-storage-panel]", wait: 10)

    metrics = panel_metrics
    expect(metrics["found"]).to be true
    expect(metrics["widthCoverage"]).to be > 0.9
    expect(metrics["wrapperBottomGap"]).to be <= 40
    expect(metrics["panelBottomGap"]).to be <= 24
  end
end
