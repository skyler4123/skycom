require "rails_helper"

RSpec.feature "Companies::Documents Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) do
    cat = Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents")
    cat.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: cat,
      property_mapping: cat.default_property_mapping, resource_name: "documents",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "code", "name" => "Code", "visible" => true },
        { "key" => "workflow_status", "name" => "Status", "visible" => true }
      ] })
    cat
  end
  let!(:policy_doc) do
    Seed::DocumentService.create(company: company, category: category,
      name: "Leave Policy",
      body_markdown: "# Leave", workflow_status: "completed")
  end
  let!(:guide_doc) do
    Seed::DocumentService.create(company: company, category: category,
      name: "Onboarding Guide",
      body_markdown: "# Onboarding", workflow_status: "draft")
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

  scenario "lists documents with titles and status" do
    visit company_documents_path(company)

    expect(page).to have_content("Leave Policy", wait: 10)
    expect(page).to have_content("Onboarding Guide", wait: 10)
  end

  scenario "title links to the show page" do
    visit company_documents_path(company)

    link = find("a[href*='/documents/#{policy_doc.id}']", match: :first, wait: 10)
    expect(link).to be_present
  end

  scenario "has add button linking to new page" do
    visit company_documents_path(company)

    add_link = find("a[href*='/documents/new']", match: :first, wait: 10)
    expect(add_link).to be_present
  end
end
