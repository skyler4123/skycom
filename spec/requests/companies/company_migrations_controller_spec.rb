# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CompanyMigrationsController", type: :request do
  let(:company) { create(:company) }
  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  before do
    get sign_in_for_test_path(email: company.user.email)
    allow(WEBSOCKET).to receive(:publish_event)
  end

  around do |example|
    original_forgery = ActionController::Base.allow_forgery_protection
    original_adapter = ActiveJob::Base.queue_adapter
    ActionController::Base.allow_forgery_protection = false
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActionController::Base.allow_forgery_protection = original_forgery
    ActiveJob::Base.queue_adapter = original_adapter
  end

  def upload_for(content)
    file = Tempfile.new([ "chunk", ".csv" ])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file, "text/csv")
  end

  def chunk_body
    File.read(fixture)
  end

  def base_path
    "/companies/#{company.id}/company_migrations"
  end

  def completed_migration
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
    CompanyMigrations::ImportService.call(company_migration: migration)
    migration.update!(workflow_status: :completed, completed_at: Time.current)
    migration
  end

  describe "GET #index" do
    it "renders the HTML shell" do
      get base_path

      expect(response).to have_http_status(:ok)
    end

    it "lists migrations as JSON" do
      migration = create(:company_migration, company: company)

      get "#{base_path}.json"

      body = JSON.parse(response.body)["company_migrations"]
      expect(body.map { |row| row["id"] }).to include(migration.id)
      expect(body.first["workflow_status"]).to eq("draft")
    end
  end

  describe "GET #show" do
    it "returns the payload with preview, chunks, and guards" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      get "#{base_path}/#{migration.id}.json"

      body = JSON.parse(response.body)["company_migration"]
      expect(body["chunk_max_bytes"]).to eq(MIGRATION_CHUNK_MAX_BYTES)
      expect(body["can_approve"]).to be(false)
      expect(body["can_rollback"]).to be(false)
      expect(body["config_locked"]).to be(false)
      expect(body["chunks"].first["row_count"]).to eq(10)
      expect(body["chunks"].first["import_status"]).to eq("uploaded")
      expect(body["preview"]["headers"]).to include("Customer Id")
      expect(body["preview"]["rows"].size).to eq(10)
    end
  end

  describe "POST #create" do
    it "creates a draft migration inside the shared Data Import folder" do
      post base_path, params: {
        company_migration: { name: "Customers import", source_filename: "customers.csv", source_file_size: 1234 }
      }

      expect(response).to have_http_status(:created)
      migration = CompanyMigration.find(JSON.parse(response.body)["company_migration"]["id"])
      expect(migration.workflow_status).to eq("draft")
      expect(migration.folder.parent&.name).to eq("Data Import")
    end

    it "returns 422 errors without a name" do
      post base_path, params: { company_migration: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "PATCH #config" do
    it "saves a valid config, sets the target, and clears the dry run" do
      migration = create(:company_migration, company: company)
      migration.update!(dry_run_result: { "passed" => true, "config_digest" => "stale" })

      patch "#{base_path}/#{migration.id}/update_config", params: {
        company_migration: { migration_mapping_config: customers_migration_config }
      }, as: :json

      expect(response).to have_http_status(:ok)
      migration.reload
      expect(migration.migration_mapping_config["version"]).to eq(1)
      expect(migration.target_resource).to eq("customers")
      expect(migration.dry_run_result).to be_nil
    end

    it "returns 422 config errors for an invalid config" do
      migration = create(:company_migration, company: company)
      config = customers_migration_config
      config["targets"][0]["identity"] = {}

      patch "#{base_path}/#{migration.id}/update_config", params: {
        company_migration: { migration_mapping_config: config }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/identity/)
      expect(migration.reload.migration_mapping_config).to eq({})
    end

    it "returns 422 once the config is locked" do
      migration = create(:company_migration, company: company, workflow_status: :processing)

      patch "#{base_path}/#{migration.id}/update_config", params: {
        company_migration: { migration_mapping_config: customers_migration_config }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/locked/)
    end
  end

  describe "POST #chunks" do
    it "uploads a chunk, records its row count, and sets the source header" do
      migration = create(:company_migration, company: company)

      post "#{base_path}/#{migration.id}/chunks", params: { file: upload_for(chunk_body), chunk_index: 0 }

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["stored_file"]["row_count"]).to eq(10)

      migration.reload
      expect(migration.total_chunks).to eq(1)
      expect(migration.total_rows).to eq(10)
      expect(migration.source_header).to be_present
    end

    it "returns 422 when the chunk header does not match the first chunk" do
      migration = create(:company_migration, company: company)
      post "#{base_path}/#{migration.id}/chunks", params: { file: upload_for(chunk_body), chunk_index: 0 }

      other = "Other,Header\n1,2\n"
      post "#{base_path}/#{migration.id}/chunks", params: { file: upload_for(other), chunk_index: 1 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/header/)
      expect(migration.reload.total_chunks).to eq(1)
    end

    it "returns 422 when chunks arrive out of order" do
      migration = create(:company_migration, company: company)

      post "#{base_path}/#{migration.id}/chunks", params: { file: upload_for(chunk_body), chunk_index: 3 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/order/)
    end

    it "returns 422 for an oversize chunk" do
      stub_const("MIGRATION_CHUNK_MAX_BYTES", 10.bytes)
      migration = create(:company_migration, company: company)

      post "#{base_path}/#{migration.id}/chunks", params: { file: upload_for(chunk_body), chunk_index: 0 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/too big/)
    end

    it "returns 422 once the import is not editable" do
      migration = create(:company_migration, company: company, workflow_status: :completed)

      post "#{base_path}/#{migration.id}/chunks", params: { file: upload_for(chunk_body), chunk_index: 0 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/not editable/)
    end

    it "returns 422 for a chunk that is not parseable CSV" do
      migration = create(:company_migration, company: company)

      post "#{base_path}/#{migration.id}/chunks",
           params: { file: upload_for("Index,\"Unclosed\n1,2\n"), chunk_index: 0 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/valid CSV/)
      expect(migration.reload.total_chunks).to eq(0)
    end
  end

  describe "POST #dry_run" do
    it "runs the dry run and stores the result" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      post "#{base_path}/#{migration.id}/dry_run"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["dry_run_result"]["passed"]).to be(true)
      expect(migration.reload.dry_run_result["passed"]).to be(true)
    end

    it "returns 422 errors when the dry run fails" do
      config = customers_migration_config
      config["targets"][0]["identity"] = {}
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: config)

      post "#{base_path}/#{migration.id}/dry_run"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end

  describe "POST #approve" do
    it "approves and enqueues the import job after a passing dry run" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
      migration.update!(dry_run_result: { "passed" => true, "config_digest" => migration.config.digest })

      post "#{base_path}/#{migration.id}/approve"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Import approved and queued")
      expect(migration.reload.workflow_status).to eq("approved")
      expect(migration.approved_at).to be_present
      expect(CompanyMigrations::ImportJob).to have_been_enqueued.with(migration.id)
    end

    it "returns 422 without a passing dry run" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      post "#{base_path}/#{migration.id}/approve"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
      expect(migration.reload.workflow_status).to eq("draft")
    end

    it "returns 422 when the config changed after the dry run" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
      migration.update!(dry_run_result: { "passed" => true, "config_digest" => "stale-digest" })

      post "#{base_path}/#{migration.id}/approve"

      expect(response).to have_http_status(:unprocessable_content)
      expect(migration.reload.workflow_status).to eq("draft")
    end

    it "returns 422 on a second approve" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
      migration.update!(dry_run_result: { "passed" => true, "config_digest" => migration.config.digest })
      post "#{base_path}/#{migration.id}/approve"

      post "#{base_path}/#{migration.id}/approve"

      expect(response).to have_http_status(:unprocessable_content)
      expect(migration.reload.workflow_status).to eq("approved")
    end
  end

  describe "POST #rollback" do
    it "queues a rollback for the latest completed import" do
      migration = completed_migration

      post "#{base_path}/#{migration.id}/rollback"

      expect(response).to have_http_status(:ok)
      expect(migration.reload.workflow_status).to eq("rolling_back")
      expect(CompanyMigrations::RollbackJob).to have_been_enqueued.with(migration.id)
    end

    it "returns 422 for an older completed import" do
      older = completed_migration
      completed_migration

      post "#{base_path}/#{older.id}/rollback"

      expect(response).to have_http_status(:unprocessable_content)
      expect(older.reload.workflow_status).to eq("completed")
    end

    it "returns 422 unless completed" do
      migration = create(:company_migration, company: company)

      post "#{base_path}/#{migration.id}/rollback"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end

  describe "DELETE #destroy" do
    it "deletes a draft import with its chunks and folder" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
      folder_id = migration.folder_id

      delete "#{base_path}/#{migration.id}"

      expect(response).to have_http_status(:ok)
      expect(CompanyMigration.exists?(migration.id)).to be(false)
      expect(Folder.exists?(folder_id)).to be(false)
      expect(StoredFile.where(company: company).count).to eq(0)
    end

    it "returns 422 for a non-draft import" do
      migration = create(:company_migration, company: company, workflow_status: :approved)

      delete "#{base_path}/#{migration.id}"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to match(/draft/)
      expect(CompanyMigration.exists?(migration.id)).to be(true)
    end
  end

  describe "authorization" do
    it "returns 403 errors for a non-owner employee" do
      stranger = create(:employee, company: company)
      get sign_in_for_test_path(email: stranger.user.email)

      get "#{base_path}.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
