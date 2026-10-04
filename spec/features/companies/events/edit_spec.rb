require "rails_helper"

RSpec.feature "Companies::Events Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:event) do
    create(:event, company: company, category: default_category,
      name: "Editable Event #{SecureRandom.hex(4)}")
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner, enums: event_enums_payload)
  end

  scenario "edit page renders prefilled form and saves changes" do
    visit edit_company_event_path(company, event)

    expect(page).to have_selector('input[name="event[name]"]', wait: 10)

    fill_in 'event[name]', with: 'Renamed Event'
    click_button "Save Event"

    expect(page).to have_current_path(company_event_path(company, event), wait: 10)
    expect(page).to have_content('Renamed Event', wait: 10)
    expect(event.reload.name).to eq('Renamed Event')
  end
end
