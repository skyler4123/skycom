require "rails_helper"

RSpec.feature "Companies::EventConfigLogs Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:config) do
    create(:event_config, company: company, category: default_category,
      create_stock_pending: true, strict_stock_hold: true)
  end

  let!(:log) do
    create(:event_config_log, company: company, event_config: config, category: default_category,
      action: :updated, category_name: default_category.name,
      create_stock_pending: true, strict_stock_hold: true, employee_name: "Jane Doe")
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner)
  end

  scenario "displays the log snapshot with actor and action" do
    visit company_event_config_log_path(company, log)

    expect(page).to have_content("Event Config Log", wait: 10)
    expect(page).to have_content("Updated")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content(default_category.name)
  end

  scenario "has back link to index page" do
    visit company_event_config_log_path(company, log)

    back_link = find("a[href*='/event_config_logs']", match: :first, wait: 10)
    expect(back_link).to be_present
  end
end
