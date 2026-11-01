# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::RunService do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def approved_import(csv: product_import_csv)
    import = create_import_with_file(company: company, category: category, csv: csv)
    Imports::DryRunService.call(import: import)
    import.reload.update!(workflow_status: :approved)
    import
  end

  describe "a successful run" do
    it "creates every valid record and writes one audit log per record" do
      import = approved_import

      result = described_class.call(import: import)
      import.reload

      expect(result[:success]).to be(true)
      expect(import.created_rows).to eq(2)
      expect(import.failed_rows).to eq(0)
      expect(import.processed_rows).to eq(2)
      expect(company.products.where(name: [ "Imported Serum", "Imported Cream" ]).count).to eq(2)
      expect(import.import_logs.count).to eq(2)
      expect(import.import_logs.map(&:record_type).uniq).to eq([ "Product" ])
      expect(import.import_logs.map(&:action).uniq).to eq([ "created" ])

      serum = company.products.find_by!(name: "Imported Serum")
      expect(serum.property_string_1).to eq("Oily")
      expect(serum.property_integer_1).to eq(30)
      expect(serum.category).to eq(category)
      expect(serum.property_mapping).to eq(category.default_property_mapping)
    end

    it "publishes progress and is idempotent only while approved/processing" do
      import = approved_import

      described_class.call(import: import)
      import.reload

      expect(company.products.count).to eq(2)

      result = described_class.call(import: import)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Import is already running")
      expect(company.products.count).to eq(2)
    end
  end

  describe "partial failures" do
    it "keeps going, counts failed rows, and logs only created records" do
      duplicate_code = "DUP-#{SecureRandom.hex(4)}"
      csv = import_csv(
        headers: [ "name", "business_type", "Skin Type Suitability", "Volume (ml)", "code" ],
        rows: [
          [ "Good Product", "physical", "Oily", "30", duplicate_code ],
          [ "Second Product", "physical", "Dry", "50", duplicate_code ]
        ]
      )
      import = approved_import(csv: csv)

      result = described_class.call(import: import)
      import.reload

      expect(result[:success]).to be(true)
      expect(import.created_rows).to eq(1)
      expect(import.failed_rows).to eq(1)
      expect(import.processed_rows).to eq(2)
      expect(company.products.where(name: "Good Product").exists?).to be(true)
      expect(company.products.where(name: "Bad Product").exists?).to be(false)
      expect(import.import_logs.count).to eq(1)
      expect(import.error_samples.first["row"]).to eq(2)
    end
  end

  describe "guards" do
    it "refuses to run without a passing dry run" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)
      import.update!(workflow_status: :approved)

      result = described_class.call(import: import)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Run a passing dry run before approving")
      expect(company.products.count).to eq(0)
    end

    it "refuses to run a draft import" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)

      result = described_class.call(import: import)

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Import is not approved")
    end
  end
end
