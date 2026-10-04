require "rails_helper"

RSpec.feature "Companies::EventConfigs New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:other_category) do
    Category.create!(company: company, resource_name: "events",
      name: "Spare Category #{SecureRandom.hex(4)}")
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner)
  end

  scenario "renders new config form with rule toggles" do
    visit new_company_event_config_path(company)

    expect(page).to have_selector('select[name="event_config[category_id]"]', wait: 10)
    expect(page).to have_selector('input[name="event_config[create_stock_pending]"]', wait: 10)
    expect(page).to have_selector('input[name="event_config[create_order_on_complete]"]', wait: 10)
  end

  scenario "creates config and redirects to show page" do
    visit new_company_event_config_path(company)

    expect(page).to have_selector('select[name="event_config[category_id]"]', wait: 10)
    expect(page).to have_selector("select[name=\"event_config[category_id]\"] option[value=\"#{other_category.id}\"]", wait: 10)
    select other_category.name, from: "event_config[category_id]"
    click_button "Save Event Config"

    expect(page).to have_content("Event Config", wait: 10)

    record = EventConfig.find_by(company: company, category: other_category)
    expect(record).to be_present
    expect(page).to have_current_path(company_event_config_path(company, record), wait: 10)
  end
end
