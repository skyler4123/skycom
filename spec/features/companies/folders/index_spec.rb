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
end
