require "rails_helper"

RSpec.feature "Companies::StorageStatistics Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:folder) { Folder.create!(company: company, name: "Bucket-#{SecureRandom.hex(3)}") }

  before do
    sign_in(owner)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [], "table_configs" => [], "categories" => [],
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {}, employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  def create_file(name:, content_type:, body:, size: nil)
    sf = folder.stored_files.build(company: company, name: name)
    sf.file.attach(io: StringIO.new(body), filename: name, content_type: content_type)
    sf.save!
    sf.update_column(:file_size, size) if size
    sf
  end

  scenario "sidebar link is visible under Storage" do
    visit company_dashboards_path(company)

    expect(page).to have_link("Storage Statistics", href: /storage_statistics/, visible: :all, wait: 10)
  end

  scenario "shows cards, breakdown, and both charts" do
    create_file(name: "big.png", content_type: "image/png", body: "a", size: 1.5.gigabytes)
    create_file(name: "notes.txt", content_type: "text/plain", body: "hello world")

    visit company_storage_statistics_path(company)

    expect(page).to have_content("Storage Statistics", wait: 10)
    expect(find('[data-statistic="total_size"]')).to have_text("1.5 GB")
    expect(find('[data-statistic="total_files"]')).to have_text("2")
    expect(find('[data-statistic-type="image"] [data-statistic-count]')).to have_text("1")
    expect(page).to have_selector('[data-chart-container="size"][data-chart-series*="1610612736"]', wait: 10)
    expect(page).to have_selector('[data-chart-container="count"][data-chart-series]', wait: 10)
    expect(page).to have_selector(".apexcharts-canvas", count: 2, wait: 10)
  end

  scenario "charts change after BE seeding and cache clear" do
    create_file(name: "notes.txt", content_type: "text/plain", body: "hello world")

    visit company_storage_statistics_path(company)
    expect(find('[data-statistic="total_files"]')).to have_text("1")

    create_file(name: "doc.pdf", content_type: "application/pdf", body: "b" * 2048)
    Rails.sync_cache.delete(CacheKeyService.company_storage_statistics(company.id))

    visit company_storage_statistics_path(company)

    expect(find('[data-statistic="total_files"]', wait: 10)).to have_text("2")
    expect(page).to have_selector('[data-chart-container="size"][data-chart-series*="2048"]', wait: 10)
  end

  scenario "shows an empty state without charts when there are no files" do
    visit company_storage_statistics_path(company)

    expect(page).to have_content("No files yet", wait: 10)
    expect(page).to have_no_selector(".apexcharts-canvas")
  end
end
