require "rails_helper"

RSpec.feature "Companies::Documents Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents") }
  let(:document_group) { Seed::DocumentGroupService.create(company: company) }

  let!(:document) do
    Seed::DocumentService.create(company: company, category: category,
      document_group: document_group, title: "Onboarding Guide",
      body_markdown: "# Welcome\n\nDo *this* first.",
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

  scenario "renders markdown body as formatted article" do
    visit company_document_path(company, document)

    article = find("article", wait: 10)
    expect(article).to have_css("h1", text: "Welcome")
    expect(article).to have_css("em", text: "this")
  end

  scenario "draft documents show a draft banner" do
    document.update!(workflow_status: "draft")

    visit company_document_path(company, document)

    expect(page).to have_content("Draft", wait: 10)
  end

  scenario "escapes hostile titles and filenames (XSS-safe)" do
    document.update!(title: '"><img src=x onerror=alert(1)>')

    visit company_document_path(company, document)

    html = find("h2", wait: 10).native.attribute("innerHTML")
    expect(html).not_to include("<img")
  end

  scenario "escapes raw HTML in the body (XSS-safe)" do
    document.update!(body_markdown: "<script>alert(1)</script>")

    visit company_document_path(company, document)

    article = find("article", wait: 10)
    html = article.native.attribute("innerHTML")
    expect(html).to include("&lt;script&gt;")
    expect(html).not_to include("<script>alert")
  end

  scenario "lists attached images and files" do
    document.image_attachments.attach(
      io: StringIO.new("pngdata"), filename: "shot.png", content_type: "image/png")
    document.file_attachments.attach(
      io: StringIO.new("%PDF-1.4 fake"), filename: "handbook.pdf", content_type: "application/pdf")
    document.save!

    visit company_document_path(company, document)

    expect(page).to have_content("shot.png", wait: 10)
    expect(page).to have_content("handbook.pdf", wait: 10)
  end

  scenario "has edit button linking to edit page" do
    visit company_document_path(company, document)

    edit_link = find("a[href*='/documents/#{document.id}/edit']", match: :first, wait: 10)
    expect(edit_link).to be_present
  end
end
