require "rails_helper"

RSpec.feature "Companies::Documents Marked", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents") }

  let!(:document) do
    Seed::DocumentService.create(company: company, category: category,
      name: "Marked Doc",
      body_markdown: "| Name | Qty |\n| --- | --- |\n| Pen | 2 |\n\n~~gone~~\n\n- [ ] todo task",
      workflow_status: "completed")
  end

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
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

  scenario "renders GFM table via marked (vanilla JS cannot)" do
    visit company_document_path(company, document)

    article = find("article", wait: 10)
    expect(article).to have_css("table", wait: 10)
    expect(article).to have_css("th", text: "Name")
    expect(article).to have_content("Pen")
  end

  scenario "renders strikethrough via marked (vanilla JS cannot)" do
    visit company_document_path(company, document)

    article = find("article", wait: 10)
    expect(article).to have_css("del, s", text: "gone", wait: 10)
  end

  scenario "new page live preview renders table via marked" do
    visit new_company_document_path(company)

    fill_in "document[body_markdown]", with: "| A | B |\n| --- | --- |\n| 1 | 2 |"

    preview = find('[data-preview="markdown"]', wait: 10)
    expect(preview).to have_css("table", wait: 10)
  end

  scenario "edit page preview renders table via marked" do
    visit edit_company_document_path(company, document)

    fill_in "document[body_markdown]", with: "| A | B |\n| --- | --- |\n| 1 | 2 |"

    preview = find('[data-preview="markdown"]', wait: 10)
    expect(preview).to have_css("table", wait: 10)
  end
end
