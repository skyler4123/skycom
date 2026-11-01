# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ImportsController", type: :request do
  let(:company) { create(:company) }
  let!(:category) { product_import_category(company: company) }

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

  def base_path
    "/companies/#{company.id}/imports"
  end

  def upload_for(content, extension: ".csv", content_type: "text/csv")
    file = Tempfile.new([ "products", extension ])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file, content_type)
  end

  def create_draft(attrs = {})
    post base_path, params: {
      import: { name: "Products #{SecureRandom.hex(4)}", description: "Q4" }.merge(attrs)
    }
    JSON.parse(response.body)["import"]
  end

  def configured_import
    import = create_draft
    patch "#{base_path}/#{import["id"]}", params: {
      import: { target_table: "products", category_id: category.id }
    }, as: :json
    import
  end

  def uploaded_import
    import = configured_import
    post "#{base_path}/#{import["id"]}/source_file", params: { file: upload_for(product_import_csv) }
    import
  end

  describe "GET #index" do
    it "renders the HTML shell" do
      get base_path

      expect(response).to have_http_status(:ok)
    end

    it "lists imports as JSON" do
      create(:import, company: company, creator: owner_of(company))

      get "#{base_path}.json"

      body = JSON.parse(response.body)["imports"]
      expect(body.size).to eq(1)
      expect(body.first["workflow_status"]).to eq("draft")
    end
  end

  describe "GET #show" do
    it "returns the setup + guards payload" do
      import = create(:import, company: company, creator: owner_of(company))

      get "#{base_path}/#{import.id}.json"

      body = JSON.parse(response.body)["import"]
      expect(body["setup_locked"]).to be(false)
      expect(body["can_approve"]).to be(false)
      expect(body["can_rollback"]).to be(false)
      expect(body["importable_resources"].map { |resource| resource["table_name"] }).to include("products")
      expect(body["schema"]).to be_nil
      expect(body["sample"]["rows"]).to eq([])
    end

    it "returns the resolved schema and sample after setup" do
      import = uploaded_import
      create_product_in_category(company: company, category: category, name: "Sampled")

      get "#{base_path}/#{import["id"]}.json"

      body = JSON.parse(response.body)["import"]
      headers = body["schema"]["headers"].map { |entry| entry["header"] }
      expect(headers).to include("Skin Type Suitability", "Volume (ml)")
      expect(body["sample"]["rows"].map { |row| row["name"] }).to include("Sampled")
      expect(body["source_filename"]).to be_present
    end

    it "returns 404 for another company's import" do
      other = create(:import, company: create(:company))

      get "#{base_path}/#{other.id}.json"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "POST #create" do
    it "creates a draft import inside the shared Imports folder" do
      import = create_draft(name: "Products Q4")

      expect(response).to have_http_status(:created)
      record = Import.find(import["id"])
      expect(record.workflow_status).to eq("draft")
      expect(record.creator).to eq(owner_of(company))
      expect(record.folder.parent&.name).to eq("Imports")
    end

    it "returns 422 errors without a name" do
      post base_path, params: { import: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "PATCH #update" do
    it "saves the target table and category and returns the schema" do
      import = create_draft

      patch "#{base_path}/#{import["id"]}", params: {
        import: { target_table: "products", category_id: category.id }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["import"]
      expect(body["target_table"]).to eq("products")
      expect(body["target_model"]).to eq("Product")
      expect(body["category_id"]).to eq(category.id)
      expect(body["schema"]["headers"].map { |entry| entry["header"] }).to include("Skin Type Suitability")
    end

    it "clears the dry run when the selection changes" do
      import = uploaded_import
      post "#{base_path}/#{import["id"]}/dry_run"
      expect(Import.find(import["id"]).dry_run_result).to be_present
      other_category = product_import_category(company: company)

      patch "#{base_path}/#{import["id"]}", params: {
        import: { target_table: "products", category_id: other_category.id }
      }, as: :json

      expect(Import.find(import["id"]).dry_run_result).to be_nil
    end

    it "returns 422 errors for a category of the wrong resource" do
      customers_category = Seed::CategoryService.create(
        company: company, name: "Customers #{SecureRandom.hex(3)}", resource_name: "customers"
      )
      import = create_draft

      patch "#{base_path}/#{import["id"]}", params: {
        import: { target_table: "products", category_id: customers_category.id }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first).to match(/is not for 'products'/)
    end

    it "returns 422 when the import is locked" do
      import = create(:import, company: company, creator: owner_of(company))
      import.update!(workflow_status: :approved)

      patch "#{base_path}/#{import.id}", params: {
        import: { target_table: "products", category_id: category.id }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Only draft imports can be edited")
    end
  end

  describe "POST #source_file" do
    it "stores the CSV and reports the row count" do
      import = configured_import

      post "#{base_path}/#{import["id"]}/source_file", params: { file: upload_for(product_import_csv) }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["row_count"]).to eq(2)
      expect(Import.find(import["id"]).source_file).to be_present
    end

    it "returns 422 for a non-CSV file" do
      import = configured_import

      post "#{base_path}/#{import["id"]}/source_file",
           params: { file: upload_for("name\n", extension: ".txt", content_type: "text/plain") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "POST #dry_run" do
    it "passes and unlocks approve" do
      import = uploaded_import

      post "#{base_path}/#{import["id"]}/dry_run"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["dry_run_result"]["passed"]).to be(true)
      expect(body["import"]["can_approve"]).to be(true)
    end

    it "returns errors and a stored failure for a wrong header" do
      import = configured_import
      csv = import_csv(headers: [ "name", "business_type", "property_string_1" ], rows: [ [ "X", "physical", "Oily" ] ])
      post "#{base_path}/#{import["id"]}/source_file", params: { file: upload_for(csv) }

      post "#{base_path}/#{import["id"]}/dry_run"

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"].first).to match(/unknown header/)
      expect(body["dry_run_result"]["passed"]).to be(false)
    end
  end

  describe "POST #approve" do
    it "returns 422 until a dry run passes" do
      import = uploaded_import

      post "#{base_path}/#{import["id"]}/approve"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Import is not ready to approve")
      expect(Import.find(import["id"]).workflow_status).to eq("draft")
    end

    it "approves and enqueues RunJob" do
      import = uploaded_import
      post "#{base_path}/#{import["id"]}/dry_run"

      expect {
        post "#{base_path}/#{import["id"]}/approve"
      }.to have_enqueued_job(Imports::RunJob)

      expect(response).to have_http_status(:ok)
      expect(Import.find(import["id"]).workflow_status).to eq("approved")
    end
  end

  describe "POST #rollback" do
    it "returns 422 for a draft import" do
      import = create(:import, company: company, creator: owner_of(company))

      post "#{base_path}/#{import.id}/rollback"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("This import cannot be rolled back")
    end

    it "queues a rollback for a completed import" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)
      Imports::DryRunService.call(import: import)
      import.reload.update!(workflow_status: :approved)
      Imports::RunService.call(import: import)
      import.reload.update!(workflow_status: :completed, completed_at: Time.current)

      expect {
        post "#{base_path}/#{import.id}/rollback"
      }.to have_enqueued_job(Imports::RollbackJob)

      expect(response).to have_http_status(:ok)
      expect(import.reload.workflow_status).to eq("rolling_back")
    end
  end

  describe "DELETE #destroy" do
    it "deletes a draft import and its folder" do
      import = create_draft
      folder = Import.find(import["id"]).folder

      delete "#{base_path}/#{import["id"]}"

      expect(response).to have_http_status(:ok)
      expect(Import.where(id: import["id"]).exists?).to be(false)
      expect(Folder.where(id: folder.id).exists?).to be(false)
    end

    it "returns 422 for a non-draft import" do
      import = create(:import, company: company, creator: owner_of(company))
      import.update!(workflow_status: :completed)

      delete "#{base_path}/#{import.id}"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to include("Only draft imports can be deleted")
    end
  end

  describe "owner-only access" do
    it "rejects a non-owner employee with errors" do
      employee = create(:employee, company: company)
      get sign_in_for_test_path(email: employee.user.email)

      get "#{base_path}.json"

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
