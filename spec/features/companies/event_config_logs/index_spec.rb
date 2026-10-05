require "rails_helper"

RSpec.feature "Companies::EventConfigLogs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:config) do
    create(:event_config, company: company, category: default_category,
      create_stock_pending: true, create_order_on_complete: true)
  end

  let!(:created_log) do
    create(:event_config_log, company: company, event_config: config, category: default_category,
      action: :created, category_name: default_category.name,
      create_stock_pending: true, employee_name: "Jane Doe")
  end

  let!(:updated_log) do
    create(:event_config_log, company: company, event_config: config, category: default_category,
      action: :updated, category_name: default_category.name,
      create_stock_pending: true, strict_stock_hold: true, employee_name: "John Smith")
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner)
  end

  scenario "index page loads and displays log rows with actor and action" do
    visit company_event_config_logs_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Event Config Logs")
    expect(page).to have_selector("th", text: "Category")
    expect(page).to have_selector("th", text: "Changed By")
    expect(page).to have_content(default_category.name)
    expect(page).to have_content("Created")
    expect(page).to have_content("Updated")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("John Smith")
  end

  scenario "index has filter controls for config, category, action and dates" do
    visit company_event_config_logs_path(company)

    expect(page).to have_selector("select[name='event_config_id']", wait: 10)
    expect(page).to have_selector("select[name='category_id']")
    expect(page).to have_selector("select[name='log_action']")
    expect(page).to have_selector("input[name='from']")
    expect(page).to have_selector("input[name='to']")
  end

  scenario "filtering by action narrows the rows" do
    visit company_event_config_logs_path(company)
    expect(page).to have_content("John Smith", wait: 10)

    select "Created", from: "log_action"
    click_button "Search"

    expect(page).to have_content("Jane Doe", wait: 10)
    expect(page).to have_no_content("John Smith")
  end

  scenario "eye icon links to the log show page" do
    visit company_event_config_logs_path(company)
    expect(page).to have_selector("table", wait: 10)

    eye_link = find("a[href*='/event_config_logs/#{created_log.id}']", match: :first)
    expect(eye_link).to be_present
  end
end
