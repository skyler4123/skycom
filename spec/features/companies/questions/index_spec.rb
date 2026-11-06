# spec/features/companies/questions/index_spec.rb
require "rails_helper"

RSpec.feature "Companies::Questions Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:category) { create(:category, company: company, resource_name: "questions", name: "General") }
  let!(:question) { create(:question, company: company, category: category, name: "Safety check") }

  before do
    sign_in(owner)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "categories" => company.categories.reset.map { |record| JSON.parse(record.to_json) },
      "property_mappings" => [],
      "table_configs" => [],
      "branches" => [],
      "departments" => [],
      "roles" => []
    )
    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "index lists questions" do
    visit company_questions_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Safety check")
    expect(page).to have_link("Add Question")
  end

  scenario "creates a single-choice question" do
    visit new_company_question_path(company)

    expect(page).to have_selector("form", wait: 10)
    fill_in "question[name]", with: "What is 2 + 2?"
    fill_in "question[options][0][content]", with: "3"
    fill_in "question[options][1][content]", with: "4"
    page.find("input[name='question[correct_option_index]'][value='1']").choose
    click_button "Create Question"

    expect(page).to have_current_path(%r{/questions/[^/]+$}, wait: 10)
    expect(page).to have_content("What is 2 + 2?")
    expect(page).to have_content("4")
  end

  scenario "renders type-specific answer fields" do
    visit new_company_question_path(company)

    expect(page).to have_selector("form", wait: 10)
    select "True / False", from: "question[question_type]"
    expect(page).to have_content("True")
    expect(page).to have_content("False")
    expect(page).not_to have_field("question[correct_text]")

    select "Text answer", from: "question[question_type]"
    expect(page).to have_field("question[correct_text]")
    expect(page).not_to have_field("question[options][0][content]")
  end

  scenario "edits a question" do
    visit edit_company_question_path(company, question)

    expect(page).to have_selector("form", wait: 10)
    fill_in "question[name]", with: "Safety check updated"
    click_button "Save Changes"

    expect(page).to have_current_path(company_question_path(company, question), wait: 10)
    expect(page).to have_content("Safety check updated")
  end

  scenario "keeps the form open and shows the server error on invalid submit" do
    visit new_company_question_path(company)

    expect(page).to have_selector("form", wait: 10)
    fill_in "question[name]", with: "Broken question"
    page.execute_script(<<~JS)
      document.querySelectorAll("input[name^='question[options]'][name$='[content]']").forEach((input) => input.removeAttribute("required"))
    JS
    click_button "Create Question"

    expect(page).to have_current_path(new_company_question_path(company), wait: 10)
    expect(page).to have_content(/at least two options/i, wait: 10)
  end
end
