# frozen_string_literal: true

require "rails_helper"

# The language menu markup is shared by the desktop and mobile headers through
# languageOptionsHTML(). This covers the desktop header after that extraction.
RSpec.feature "Header language switch", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }

  before do
    sign_in(user)
  end

  after do
    begin
      page.execute_script("localStorage.setItem('languageCode', 'en')")
    rescue StandardError
      # The browser may already be closed when a scenario fails early.
    end
  end

  scenario "switches the signed-in app to Vietnamese from the shared menu" do
    visit company_dashboards_path(company)

    find("[data-language-switch]", wait: 10).click
    find("[data-language-code-param='vi']", wait: 10).click

    expect(page).to have_content("Sức khỏe công ty", wait: 10)
    expect(page.evaluate_script("localStorage.getItem('languageCode')")).to eq("vi")
    expect(find("[data-language-switch]").text.strip).to eq("VI")
  end
end
