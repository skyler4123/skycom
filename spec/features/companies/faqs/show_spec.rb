require "rails_helper"

RSpec.feature "Companies::Faqs Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

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

  scenario "opens from System and renders the FAQ heading" do
    visit company_dashboards_path(company)

    expect(page).to have_link("FAQ", href: company_faq_path(company), visible: :all, wait: 10)

    visit company_faq_path(company)

    expect(page).to have_current_path(company_faq_path(company))
    expect(page).to have_content("Frequently asked questions", wait: 10)
  end

  scenario "renders the first group and a question" do
    visit company_faq_path(company)

    expect(page).to have_content("Answers to common questions about using Skycom.", wait: 10)
    expect(page).to have_selector("[data-faq-group='getting_started']", wait: 10)
    expect(page).to have_content("Getting started & company setup")
    expect(page).to have_content("What is Skycom, and what can one company workspace manage?")
  end

  scenario "searches English questions and answers" do
    visit company_faq_path(company)
    expect(page).to have_content("What is Skycom, and what can one company workspace manage?", wait: 10)

    fill_in "faq-search", with: "ownership"

    expect(page).to have_content("What is the Owner role, and can ownership be transferred?", wait: 10)
    expect(page).to have_no_content("What is Skycom, and what can one company workspace manage?")
  end

  scenario "searches Vietnamese without diacritics" do
    page.execute_script("localStorage.setItem('languageCode', 'vi')")
    visit company_faq_path(company)

    expect(page).to have_content("Câu hỏi thường gặp", wait: 10)

    fill_in "faq-search", with: "quyen so huu"

    expect(page).to have_content("Vai trò Owner là gì và có thể chuyển quyền sở hữu không?", wait: 10)
  end

  scenario "opens a question from a deep link" do
    visit "#{company_faq_path(company)}#faq-what-is-skycom"

    expect(page).to have_selector("[data-faq-question='what-is-skycom'][open]", wait: 10)
    expect(page).to have_content("a multi-tenant business management platform", wait: 10)
  end

  scenario "explains per-product tax codes" do
    visit "#{company_faq_path(company)}#faq-per-product-tax"

    expect(page).to have_selector("[data-faq-question='per-product-tax'][open]", wait: 10)
    expect(page).to have_content("Yes. Create each rate under Tax", wait: 10)
    expect(page).to have_link("Open Tax Codes", wait: 10)
  end

  scenario "searches answer text inside a selected group" do
    visit company_faq_path(company)
    expect(page).to have_selector("[data-faq-group]", count: 20, wait: 10)

    click_button "Inventory & stock"
    fill_in "faq-search", with: "Stock Import"

    expect(page).to have_content("How do I receive stock?", wait: 10)
    expect(page).not_to have_content("What must be enabled before a cashier can use POS?")
  end

  scenario "marks a planned answer" do
    visit company_faq_path(company)

    fill_in "faq-search", with: "ownership"

    expect(page).to have_selector("[data-faq-badge='planned']", wait: 10)
    expect(page).to have_content("Not available yet")
  end

  scenario "renders all twenty groups and the full question count" do
    visit company_faq_path(company)

    expect(page).to have_selector("[data-faq-group]", count: 20, wait: 10)
    expect(page).to have_content("20 groups")
    expect(page).to have_content("167 questions")
  end

  scenario "filters to one group" do
    visit company_faq_path(company)
    expect(page).to have_selector("[data-faq-group]", count: 20, wait: 10)

    click_button "Inventory & stock"

    expect(page).to have_selector("[data-faq-group]", count: 1)
    expect(page).to have_selector("[data-faq-group='inventory_stock']")
    within("[data-faq-results]") do
      expect(page).to have_no_content("Getting started & company setup")
    end
  end

  scenario "expands and collapses all questions" do
    visit company_faq_path(company)
    expect(page).to have_content("What is Skycom, and what can one company workspace manage?", wait: 10)

    click_button "Expand all"
    expect(page).to have_selector("[data-faq-question='what-is-skycom'][open]")

    click_button "Collapse all"
    expect(page).to have_no_selector("[data-faq-question='what-is-skycom'][open]")
  end

  scenario "shows an empty search state and clears it" do
    visit company_faq_path(company)
    expect(page).to have_selector("[data-faq-group]", count: 20, wait: 10)

    fill_in "faq-search", with: "zzzzzz"
    expect(page).to have_content("No questions match your search.")

    click_button "Clear search"
    expect(page).to have_selector("[data-faq-group]", count: 20)
    expect(find("[data-faq-search]").value).to eq("")
  end

  scenario "marks a manual-step answer and links to Help Center" do
    visit company_faq_path(company)

    fill_in "faq-search", with: "reverse money"
    expect(page).to have_selector("[data-faq-badge='manual']", wait: 10)

    expect(page).to have_link("Open a Help Center ticket", href: /company_tickets/)
  end
end
