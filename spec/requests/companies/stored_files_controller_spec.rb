# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StoredFilesController", type: :request do
  let(:company) { create(:company) }
  let!(:folder) { Folder.create!(company: company, name: "Bucket-A") }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def txt_upload
    Rack::Test::UploadedFile.new(Rails.root.join("faker/files/Untitled document.txt"), "text/plain")
  end

  describe "POST #create" do
    it "uploads a real faker file and syncs audit columns" do
      expect {
        post "/companies/#{company.id}/stored_files", params: {
          stored_file: { name: "notes.txt", folder_id: folder.id, file: txt_upload }
        }
      }.to change(StoredFile, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)["stored_file"]
      expect(body["file_size"]).to be > 0
      expect(body["content_type"]).to eq("text/plain")
    end

    it "returns 422 errors without folder (no top-level files)" do
      expect {
        post "/companies/#{company.id}/stored_files", params: {
          stored_file: { name: "orphan.txt", file: txt_upload }
        }
      }.not_to change(StoredFile, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "returns 422 errors for oversize upload" do
      big = Tempfile.new([ "big", ".pdf" ])
      big.binmode
      big.write("a" * (STORED_FILE_MAX_SIZES_BY_TYPE[:pdf] + 1))
      big.rewind
      upload = Rack::Test::UploadedFile.new(big, "application/pdf")

      post "/companies/#{company.id}/stored_files", params: {
        stored_file: { name: "big.pdf", folder_id: folder.id, file: upload }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/too big/i)
    ensure
      big&.close!
    end

    it "returns 422 errors for disallowed type" do
      sh = Tempfile.new([ "run", ".sh" ])
      sh.write("#!/bin/sh")
      sh.rewind
      upload = Rack::Test::UploadedFile.new(sh, "application/x-sh")

      post "/companies/#{company.id}/stored_files", params: {
        stored_file: { name: "run.sh", folder_id: folder.id, file: upload }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    ensure
      sh&.close!
    end
  end

  describe "GET #download" do
    it "redirects to the blob for download" do
      sf = folder.stored_files.build(company: company, name: "notes.txt")
      sf.file.attach(io: StringIO.new("hello"), filename: "notes.txt", content_type: "text/plain")
      sf.save!

      get "/companies/#{company.id}/stored_files/#{sf.id}/download"

      expect(response).to have_http_status(:found)
      expect(response.location).to include("rails/active_storage")
    end

    it "returns 404 errors for foreign file" do
      other = create(:company)
      foreign_folder = Folder.create!(company: other, name: "Foreign")
      foreign = foreign_folder.stored_files.build(company: other, name: "x.pdf")
      foreign.file.attach(io: StringIO.new("pdfdata"), filename: "x.pdf", content_type: "application/pdf")
      foreign.save!

      get "/companies/#{company.id}/stored_files/#{foreign.id}/download"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "DELETE #destroy" do
    it "destroys file and purges blob" do
      sf = folder.stored_files.build(company: company, name: "notes.txt")
      sf.file.attach(io: StringIO.new("hello"), filename: "notes.txt", content_type: "text/plain")
      sf.save!

      expect {
        delete "/companies/#{company.id}/stored_files/#{sf.id}.json"
      }.to change(StoredFile, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 errors for foreign file destroy" do
      other = create(:company)
      foreign_folder = Folder.create!(company: other, name: "Foreign")
      foreign = foreign_folder.stored_files.build(company: other, name: "x.pdf")
      foreign.file.attach(io: StringIO.new("pdfdata"), filename: "x.pdf", content_type: "application/pdf")
      foreign.save!

      expect {
        delete "/companies/#{company.id}/stored_files/#{foreign.id}.json"
      }.not_to change(StoredFile, :count)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "cross-company guards" do
    it "returns 422 errors for cross-company folder_id" do
      other = create(:company)
      foreign_folder = Folder.create!(company: other, name: "Foreign")

      expect {
        post "/companies/#{company.id}/stored_files", params: {
          stored_file: {
            name: "x.txt", folder_id: foreign_folder.id,
            file: Rack::Test::UploadedFile.new(Rails.root.join("faker/files/Untitled document.txt"), "text/plain")
          }
        }
      }.not_to change(StoredFile, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "returns 422 errors for cross-company attachable" do
      other = create(:company)
      other_customer = create(:customer, company: other)
      other_order = create(:order, company: other, customer: other_customer)
      foreign_invoice = create(:invoice, order: other_order)

      expect {
        post "/companies/#{company.id}/stored_files", params: {
          stored_file: {
            name: "x.txt", folder_id: folder.id,
            attachable_type: "Invoice", attachable_id: foreign_invoice.id,
            file: Rack::Test::UploadedFile.new(Rails.root.join("faker/files/Untitled document.txt"), "text/plain")
          }
        }
      }.not_to change(StoredFile, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
