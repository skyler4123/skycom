# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::FileIngestService do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }
  let(:import) { create(:import, company: company, creator: owner_of(company)) }

  def upload(content, filename: "products.csv", content_type: "text/csv", size: nil)
    file = double(
      size: size || content.bytesize,
      content_type: content_type,
      original_filename: filename,
      read: content
    )

    described_class.call(import: import, file: file, company: company)
  end

  describe "a valid upload" do
    it "attaches the file in the import folder and records its metadata" do
      content = product_import_csv

      result = upload(content)
      import.reload

      expect(result[:success]).to be(true)
      expect(result[:row_count]).to eq(2)
      expect(import.source_file).to be_present
      expect(import.source_file.folder).to eq(import.folder)
      expect(import.source_file.company).to eq(company)
      expect(import.source_filename).to eq("products.csv")
      expect(import.source_file_size).to eq(content.bytesize)
      expect(import.source_digest).to eq(Digest::SHA256.hexdigest(content))
      expect(import.total_rows).to eq(2)
    end

    it "replaces the previous file and clears the dry run" do
      upload(product_import_csv)
      import.reload.update!(
        dry_run_result: { "passed" => true, "schema_digest" => "x", "source_digest" => import.source_digest },
        schema_snapshot: { "digest" => "x" }
      )
      old_file_id = import.source_file.id

      replacement = import_csv(headers: [ "name", "business_type" ], rows: [ [ "Only", "physical" ] ])
      result = upload(replacement, filename: "replacement.csv")
      import.reload

      expect(result[:success]).to be(true)
      expect(import.source_file.id).not_to eq(old_file_id)
      expect(import.source_filename).to eq("replacement.csv")
      expect(import.total_rows).to eq(1)
      expect(import.dry_run_result).to be_nil
      expect(import.schema_snapshot).to eq({})
      expect(StoredFile.where(id: old_file_id).exists?).to be(false)
    end
  end

  describe "failures" do
    it "requires a file" do
      result = described_class.call(import: import, file: nil, company: company)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("file is required")
    end

    it "rejects a non-CSV file" do
      result = upload(product_import_csv, filename: "products.txt", content_type: "text/plain")

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("file must be a CSV")
    end

    it "rejects an oversized file before reading it" do
      result = upload("name\n", size: IMPORT_MAX_FILE_BYTES + 1)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/too big/)
    end

    it "rejects a header-only file" do
      result = upload("name,business_type\n")

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("file has no data rows")
    end

    it "rejects a non-CSV body" do
      result = upload("not,a,valid\n\"unterminated\n")

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("file is not valid CSV")
    end

    it "rejects an upload on a locked import" do
      import.update!(workflow_status: :approved)

      result = upload(product_import_csv)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("import is locked")
    end

    it "rejects more than IMPORT_MAX_ROWS data rows" do
      rows = Array.new(IMPORT_MAX_ROWS + 1) { [ "Row", "physical" ] }
      content = import_csv(headers: [ "name", "business_type" ], rows: rows)

      result = upload(content)

      expect(result[:success]).to be(false)
      expect(result[:errors].first).to match(/more than #{IMPORT_MAX_ROWS} rows/)
    end
  end
end
