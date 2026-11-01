# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::DryRunService do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }

  def dry_run(import)
    described_class.call(import: import)
  end

  describe "a passing run" do
    it "validates every row and stores both digests" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)

      result = dry_run(import)
      import.reload

      expect(result[:success]).to be(true)
      expect(result[:result]["passed"]).to be(true)
      expect(result[:result]["total_rows"]).to eq(2)
      expect(result[:result]["valid_rows"]).to eq(2)
      expect(result[:result]["invalid_rows"]).to eq(0)
      expect(result[:result]["header_errors"]).to be_empty
      expect(result[:result]["row_errors"]).to be_empty
      expect(import.dry_run_result).to eq(result[:result])
      expect(import.schema_snapshot["headers"]).to be_present
      expect(import.dry_run_result["source_digest"]).to eq(import.source_digest)
      expect(import.dry_run_result["schema_digest"]).to eq(import.schema_snapshot["digest"])
    end

    it "does not write target records" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)

      expect { dry_run(import) }.not_to change { company.products.count }
    end

    it "does not auto-populate blank property slots with random values" do
      csv = import_csv(
        headers: [ "name", "business_type" ],
        rows: [ [ "Sparse Product", "physical" ] ]
      )
      import = create_import_with_file(company: company, category: category, csv: csv)

      result = dry_run(import)

      expect(result[:success]).to be(false)
      expect(result[:result]["row_errors"].first["errors"]).to include(/Property string 1/)
    end
  end

  describe "header failures" do
    it "rejects the raw property slot name" do
      csv = import_csv(
        headers: [ "name", "business_type", "property_string_1", "Volume (ml)" ],
        rows: [ [ "Serum", "physical", "Oily", "30" ] ]
      )
      import = create_import_with_file(company: company, category: category, csv: csv)

      result = dry_run(import)

      expect(result[:success]).to be(false)
      expect(result[:result]["header_errors"].first).to match(/unknown header\(s\): property_string_1/)
      expect(result[:result]["valid_rows"]).to eq(0)
    end

    it "rejects duplicate headers" do
      csv = "name,business_type,name\nSerum,physical,Other\n"
      import = create_import_with_file(company: company, category: category, csv: csv)

      result = dry_run(import)

      expect(result[:result]["header_errors"].first).to match(/duplicate header/)
    end
  end

  describe "row failures" do
    it "reports missing required attributes" do
      csv = import_csv(
        headers: [ "name", "business_type", "Skin Type Suitability", "Volume (ml)" ],
        rows: [ [ "", "physical", "Oily", "30" ] ]
      )
      import = create_import_with_file(company: company, category: category, csv: csv)

      result = dry_run(import)

      expect(result[:success]).to be(false)
      expect(result[:result]["invalid_rows"]).to eq(1)
      expect(result[:result]["row_errors"].first["errors"]).to include("Name can't be blank")
    end

    it "reports a bad property value without aborting the other rows" do
      csv = import_csv(
        headers: [ "name", "business_type", "Skin Type Suitability", "Volume (ml)" ],
        rows: [
          [ "Good", "physical", "Oily", "30" ],
          [ "Bad", "physical", "Dry", "not-a-number" ]
        ]
      )
      import = create_import_with_file(company: company, category: category, csv: csv)

      result = dry_run(import)

      expect(result[:result]["valid_rows"]).to eq(1)
      expect(result[:result]["invalid_rows"]).to eq(1)
      expect(result[:result]["row_errors"].first["row"]).to eq(2)
    end
  end

  describe "guards" do
    it "fails without a file" do
      import = create(:import, company: company, creator: owner_of(company), target_table: "products", category: category)

      result = dry_run(import)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Upload a CSV file first")
    end

    it "fails when the import is locked" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)
      import.update!(workflow_status: :approved)

      result = dry_run(import)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("import is locked")
    end
  end
end
