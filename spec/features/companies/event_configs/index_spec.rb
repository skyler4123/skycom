require "rails_helper"

RSpec.feature "Companies::EventConfigs Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:config) do
    create(:event_config, company: company, category: default_category,
      create_stock_pending: true, create_order_on_complete: true)
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner)
  end

  scenario "index page loads and displays configs table" do
    visit company_event_configs_path(company)

    expect(page).to have_selector('table', wait: 10)
    expect(page).to have_content(default_category.name)
    expect(page).to have_selector('tbody tr')
  end

  scenario "edit button links to edit page for config" do
    visit company_event_configs_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/event_configs/#{config.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end
end
