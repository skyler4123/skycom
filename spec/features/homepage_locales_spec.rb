require "rails_helper"

RSpec.feature "Homepage locales", type: :feature do
  it "switches from English to Vietnamese and back with crawlable links" do
    visit root_path

    expect(page.find("html")["lang"]).to eq("en")
    expect(page).to have_content("One Account. Multiple Businesses.")

    click_link "Tiếng Việt", match: :first

    expect(page).to have_current_path("/vi")
    expect(page.find("html")["lang"]).to eq("vi")
    expect(page).to have_content("Một tài khoản. Nhiều doanh nghiệp.")
    expect(page).not_to have_content("One Account. Multiple Businesses.")

    click_link "English", match: :first

    expect(page).to have_current_path("/")
    expect(page.find("html")["lang"]).to eq("en")
    expect(page).to have_content("One Account. Multiple Businesses.")
  end

  it "links the logo to the current locale homepage" do
    visit "/vi"

    within("header") do
      first("a", text: "Skycom").click
    end

    expect(page).to have_current_path("/vi")
  end

  it "aligns the app language preference and demo labels with the chosen locale", js: true do
    visit root_path

    click_link "Tiếng Việt", match: :first

    expect(page).to have_current_path("/vi")
    expect(page.evaluate_script("localStorage.getItem('languageCode')")).to eq("vi")
    expect(find('[data-live="txns"]').text).to include("giao dịch")
    expect(find('[data-live="sales"]').text).to match(/[\d.,]+\s*\$/)
  end
end
