# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StorageStatisticsController", type: :request do
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

  def attach_file(name:, content_type:, body:)
    sf = folder.stored_files.build(company: company, name: name)
    sf.file.attach(io: StringIO.new(body), filename: name, content_type: content_type)
    sf.save!
    sf
  end

  describe "GET #index" do
    it "returns totals and per-type buckets" do
      attach_file(name: "pic.png", content_type: "image/png", body: "a" * 2048)
      attach_file(name: "doc.pdf", content_type: "application/pdf", body: "b" * 100)
      attach_file(name: "notes.txt", content_type: "text/plain", body: "hello world")
      attach_file(name: "pack.zip", content_type: "application/zip", body: "c" * 50)

      get "/companies/#{company.id}/storage_statistics.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["total_size"]).to eq(2209)
      expect(body["total_files"]).to eq(4)
      expect(body["total_folders"]).to eq(1)
      expect(body["by_type"].map { |b| b["type"] }).to eq(%w[image pdf office text archive])
      expect(body["by_type"]).to include(
        { "type" => "image", "count" => 1, "size" => 2048 },
        { "type" => "pdf", "count" => 1, "size" => 100 },
        { "type" => "office", "count" => 0, "size" => 0 },
        { "type" => "text", "count" => 1, "size" => 11 },
        { "type" => "archive", "count" => 1, "size" => 50 }
      )
    end

    it "returns zeroed buckets for an empty company" do
      get "/companies/#{company.id}/storage_statistics.json"

      body = JSON.parse(response.body)
      expect(body["total_size"]).to eq(0)
      expect(body["total_files"]).to eq(0)
      expect(body["by_type"].size).to eq(5)
      expect(body["by_type"].all? { |b| b["count"].zero? && b["size"].zero? }).to be true
    end

    it "returns the HTML shell" do
      get company_storage_statistics_path(company)

      expect(response).to have_http_status(:ok)
    end

    it "serves cached numbers until the cache is cleared" do
      attach_file(name: "notes.txt", content_type: "text/plain", body: "hello world")
      get "/companies/#{company.id}/storage_statistics.json"
      expect(JSON.parse(response.body)["total_files"]).to eq(1)

      attach_file(name: "doc.pdf", content_type: "application/pdf", body: "b" * 100)
      get "/companies/#{company.id}/storage_statistics.json"
      expect(JSON.parse(response.body)["total_files"]).to eq(1) # cached

      Rails.sync_cache.delete("storage_statistics/#{company.id}")
      get "/companies/#{company.id}/storage_statistics.json"
      expect(JSON.parse(response.body)["total_files"]).to eq(2)
      expect(JSON.parse(response.body)["total_size"]).to eq(111)
    end

    it "returns forbidden with an errors key when the employee cannot read stored files" do
      allow_any_instance_of(Employee).to receive(:can?).with(:read, StoredFile).and_return(false)

      get "/companies/#{company.id}/storage_statistics.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end
end
