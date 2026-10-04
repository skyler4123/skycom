require "rails_helper"

RSpec.feature "Companies::EventConfigs Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:category) do
    Category.create!(company: company, resource_name: "events",
      name: "Booking #{SecureRandom.hex(4)}")
  end

  let!(:config) do
    create(:event_config, company: company, category: category,
      create_stock_pending: true, create_order_on_complete: true)
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner)
  end

  scenario "title shows which event category the config applies to" do
    visit edit_company_event_config_path(company, config)

    expect(page).to have_content("Edit Event Config", wait: 10)
    expect(page).to have_content(category.name, wait: 10)
  end

  scenario "category dropdown is removed" do
    visit edit_company_event_config_path(company, config)

    expect(page).to have_selector('input[name="event_config[create_stock_pending]"]', wait: 10)
    expect(page).to have_no_selector('select[name="event_config[category_id]"]')
  end

  scenario "each rule toggle shows a purpose tooltip" do
    visit edit_company_event_config_path(company, config)

    expect(page).to have_selector('input[name="event_config[create_stock_pending]"]', wait: 10)
    expect(page).to have_selector('[data-controller="tooltip"]', minimum: 5, wait: 10)
  end
end
