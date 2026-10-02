require "rails_helper"

RSpec.feature "Companies::Events Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:event) do
    create(:event, company: company, category: default_category,
      name: "Showcase Event #{SecureRandom.hex(4)}",
      start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner, enums: event_enums_payload)
  end

  scenario "show page displays event details" do
    visit company_event_path(company, event)

    expect(page).to have_content(event.name, wait: 10)
    expect(page).to have_link("Edit Event")
    expect(page).to have_link("Back to Events")
  end
end
