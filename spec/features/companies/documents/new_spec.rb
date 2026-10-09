require "rails_helper"

RSpec.feature "Companies::Documents New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents") }

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
      enums: {
        document: {
          business_types: Document.business_types.map { |k, _| { name: k.humanize, value: k } },
          workflow_statuses: Document.workflow_statuses.map { |k, _| { name: k.humanize, value: k } }
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders name, body, preview fields" do
    visit new_company_document_path(company)

    expect(page).to have_selector('input[name="document[name]"]', wait: 10)
    expect(page).to have_selector('textarea[name="document[body_markdown]"]', wait: 10)
    expect(page).to have_selector('[data-preview="markdown"]', wait: 10)
  end

  scenario "live preview renders markdown while typing" do
    visit new_company_document_path(company)

    fill_in 'document[name]', with: 'Preview Doc'
    fill_in 'document[body_markdown]', with: '# Welcome'

    preview = find('[data-preview="markdown"]', wait: 10)
    expect(preview).to have_css('h1', text: 'Welcome', wait: 10)
  end

  scenario "creates document and redirects to show page" do
    visit new_company_document_path(company)

    fill_in 'document[name]', with: 'Leave Policy'
    fill_in 'document[body_markdown]', with: "# Leave\n\nTake **days** off."

    click_button "Save Document"

    created = Document.find_by(name: "Leave Policy")
    expect(created).to be_present
    expect(page).to have_current_path(company_document_path(company, created), wait: 10)
    expect(page).to have_content('Leave Policy', wait: 10)
    expect(created.body_markdown).to include("# Leave")
  end
end
