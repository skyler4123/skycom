# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::FoldersController", type: :request do
  let(:company) { create(:company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "lists root folders as buckets" do
      root = Folder.create!(company: company, name: "Bucket-A")
      Folder.create!(company: company, name: "Bucket-B")

      get "/companies/#{company.id}/folders.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["folders"].map { |f| f["id"] }).to include(root.id)
    end

    it "lists children when parent_id given" do
      parent = Folder.create!(company: company, name: "Bucket-A")
      child = Folder.create!(company: company, name: "Child", parent: parent)

      get "/companies/#{company.id}/folders.json", params: { parent_id: parent.id }

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["folders"].map { |f| f["id"] }
      expect(ids).to contain_exactly(child.id)
    end
  end

  describe "GET #show" do
    it "returns folder with subfolders files and breadcrumbs" do
      parent = Folder.create!(company: company, name: "Bucket-A")
      child = Folder.create!(company: company, name: "Child", parent: parent)
      sf = parent.stored_files.build(company: company, name: "doc.pdf")
      sf.file.attach(io: StringIO.new("pdfdata"), filename: "doc.pdf", content_type: "application/pdf")
      sf.save!

      get "/companies/#{company.id}/folders/#{parent.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["folder"]["id"]).to eq(parent.id)
      expect(body["subfolders"].map { |f| f["id"] }).to contain_exactly(child.id)
      expect(body["files"].map { |f| f["id"] }).to contain_exactly(sf.id)
      expect(body["breadcrumbs"].map { |b| b["id"] }).to include(parent.id)
    end

    it "returns 404 errors for foreign folder" do
      other = create(:company)
      foreign = Folder.create!(company: other, name: "Foreign")

      get "/companies/#{company.id}/folders/#{foreign.id}.json"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "POST #create" do
    it "creates a root bucket" do
      expect {
        post "/companies/#{company.id}/folders.json", params: { folder: { name: "Bucket-A" } }, as: :json
      }.to change(Folder, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["folder"]["name"]).to eq("Bucket-A")
    end

    it "returns 422 errors for duplicate name" do
      Folder.create!(company: company, name: "Bucket-A")

      post "/companies/#{company.id}/folders.json", params: { folder: { name: "Bucket-A" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "returns 422 errors when folder param is missing" do
      post "/companies/#{company.id}/folders.json", params: {}, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "DELETE #destroy" do
    it "destroys an empty folder" do
      folder = Folder.create!(company: company, name: "Bucket-A")

      expect {
        delete "/companies/#{company.id}/folders/#{folder.id}.json"
      }.to change(Folder, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "blocks destroy when folder is not empty" do
      parent = Folder.create!(company: company, name: "Bucket-A")
      Folder.create!(company: company, name: "Child", parent: parent)

      delete "/companies/#{company.id}/folders/#{parent.id}.json"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
      expect(Folder.exists?(parent.id)).to be true
    end

    it "returns 404 errors for foreign folder destroy" do
      other = create(:company)
      foreign = Folder.create!(company: other, name: "Foreign")

      expect {
        delete "/companies/#{company.id}/folders/#{foreign.id}.json"
      }.not_to change(Folder, :count)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "PATCH #update" do
    it "returns 422 errors for descendant parent cycle" do
      parent = Folder.create!(company: company, name: "Parent")
      child = Folder.create!(company: company, name: "Child", parent: parent)

      patch "/companies/#{company.id}/folders/#{parent.id}.json",
        params: { folder: { parent_id: child.id } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
