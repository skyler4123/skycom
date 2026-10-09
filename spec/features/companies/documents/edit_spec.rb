require "rails_helper"

RSpec.feature "Companies::Documents Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents") }

  let!(:document) do
    Seed::DocumentService.create(company: company, category: category,
      name: "Old Name",
      body_markdown: "# Old", workflow_status: "draft")
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

  scenario "prefills name and body" do
    visit edit_company_document_path(company, document)

    expect(page).to have_field('document[name]', with: 'Old Name', wait: 10)
    expect(page).to have_field('document[body_markdown]', with: '# Old', wait: 10)
  end

  scenario "updates body and redirects to show page" do
    visit edit_company_document_path(company, document)

    fill_in 'document[name]', with: 'New Name'
    fill_in 'document[body_markdown]', with: '## New body'

    click_button "Save Document"

    expect(page).to have_current_path(company_document_path(company, document), wait: 10)
    expect(page).to have_content('New Name', wait: 10)
    expect(document.reload.body_markdown).to eq('## New body')
  end
end
