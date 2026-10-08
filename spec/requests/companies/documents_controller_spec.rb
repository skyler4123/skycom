# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::DocumentsController", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "documents") }
  let(:document_group) { Seed::DocumentGroupService.create(company: company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def image_upload
    Rack::Test::UploadedFile.new(
      Rails.root.join("faker/images/randoms/580-200x300.jpg"), "image/jpeg")
  end

  def pdf_upload
    file = Tempfile.new([ "doc", ".pdf" ])
    file.binmode
    file.write("%PDF-1.4 fake")
    file.rewind
    Rack::Test::UploadedFile.new(file, "application/pdf")
  end

  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "documents" }
    let(:index_class) { Document }
    let(:json_key) { "documents" }
    let(:base_json_path) { "/companies/#{company.id}/documents.json" }
    let(:record) { ->(company:, category:, **attrs) { Seed::DocumentService.create(company: company, category: category, **attrs) } }
  end

  describe "GET #index / #show / #new / #edit shells" do
    let!(:document) { Seed::DocumentService.create(company: company, category: category, document_group: document_group) }

    it "renders shells and JSON payloads" do
      get "/companies/#{company.id}/documents"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/documents.json", params: { category_id: category.id }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["documents"].map { |d| d["id"] }).to include(document.id)
      expect(body).to have_key("pagination")
      entry = body["documents"].find { |d| d["id"] == document.id }
      expect(entry).to include("body_markdown", "image_urls", "file_urls")

      get "/companies/#{company.id}/documents/#{document.id}"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/documents/#{document.id}.json"
      expect(JSON.parse(response.body)["document"]["id"]).to eq(document.id)

      get "/companies/#{company.id}/documents/new"
      expect(response).to have_http_status(:ok)

      get "/companies/#{company.id}/documents/#{document.id}/edit"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates with markdown and attachments, then redirects to show" do
      expect {
        post "/companies/#{company.id}/documents", params: {
          document: {
            title: "Onboarding Guide",
            body_markdown: "# Welcome\n\nDo **this** first.",
            category_id: category.id,
            document_group_id: document_group.id,
            workflow_status: "draft",
            image_attachments: [ image_upload ],
            file_attachments: [ pdf_upload ]
          }
        }
      }.to change(Document, :count).by(1)

      expect(response).to have_http_status(:found)
      created = Document.last
      expect(created.body_markdown).to include("# Welcome")
      expect(created.image_attachments).to be_attached
      expect(created.file_attachments).to be_attached
      expect(response.location).to include("/documents/#{created.id}")
    end

    it "redirects without creating when title is blank" do
      expect {
        post "/companies/#{company.id}/documents", params: {
          document: { title: "", category_id: category.id, document_group_id: document_group.id }
        }
      }.not_to change(Document, :count)

      expect(response).to have_http_status(:found)
    end
  end

  describe "PATCH #update" do
    let!(:document) { Seed::DocumentService.create(company: company, category: category, document_group: document_group) }

    it "updates via JSON and keeps existing attachments" do
      document.image_attachments.attach(
        io: StringIO.new("pngdata"), filename: "a.png", content_type: "image/png")
      document.save!

      patch "/companies/#{company.id}/documents/#{document.id}.json", params: {
        document: { title: "Renamed", body_markdown: "## New body" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["document"]
      expect(body["title"]).to eq("Renamed")
      expect(body["body_markdown"]).to eq("## New body")
      expect(document.reload.image_attachments).to be_attached
    end

    it "returns 422 errors for invalid JSON updates" do
      patch "/companies/#{company.id}/documents/#{document.id}.json", params: {
        document: { title: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "cross-company scoping" do
    it "returns 404 for a foreign document" do
      other = create(:company)
      other_group = Seed::DocumentGroupService.create(company: other)
      foreign = Seed::DocumentService.create(company: other, document_group: other_group)

      get "/companies/#{company.id}/documents/#{foreign.id}.json"

      expect(response).to have_http_status(:not_found)
    end
  end
end
