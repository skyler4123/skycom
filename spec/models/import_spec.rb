# frozen_string_literal: true

require "rails_helper"

RSpec.describe Import, type: :model do
  let!(:company) { create(:company) }

  def build_import(**attrs)
    Import.new(
      {
        company: company,
        folder: Folder.create!(company: company, name: "Import #{SecureRandom.hex(4)}"),
        creator: owner_of(company),
        name: "Products #{SecureRandom.hex(4)}"
      }.merge(attrs)
    )
  end

  describe "workflow_status" do
    it "maps the import lifecycle values" do
      expect(described_class.workflow_statuses).to eq(
        "draft" => 0,
        "approved" => 1,
        "processing" => 2,
        "completed" => 3,
        "failed" => 4,
        "rolling_back" => 5,
        "rolled_back" => 6
      )
    end
  end

  describe "validations" do
    it "requires a name" do
      import = build_import(name: nil)

      expect(import).not_to be_valid
      expect(import.errors[:name]).to be_present
    end

    it "requires a unique name inside the company" do
      name = "Products #{SecureRandom.hex(4)}"
      build_import(name: name).save!

      import = build_import(name: name)

      expect(import).not_to be_valid
      expect(import.errors[:name]).to be_present
    end

    it "rejects a target table outside IMPORTABLE_RESOURCES" do
      import = build_import(target_table: "orders")

      expect(import).not_to be_valid
      expect(import.errors[:target_table]).to be_present
    end

    it "accepts an allowlisted target table" do
      import = build_import(target_table: "products")

      expect(import).to be_valid
    end
  end

  describe "#target_model_name" do
    it "maps the table to the model name" do
      expect(build_import(target_table: "products").target_model_name).to eq("Product")
      expect(build_import.target_model_name).to be_nil
    end
  end

  describe "#setup_locked?" do
    it "is unlocked only while draft" do
      import = build_import

      expect(import.setup_locked?).to be(false)
      import.workflow_status = :approved
      expect(import.setup_locked?).to be(true)
    end
  end

  describe "#approvable?" do
    it "is false without a file" do
      category = product_import_category(company: company)
      import = build_import(target_table: "products", category: category)
      import.save!

      expect(import.approvable?).to be(false)
    end

    it "is false until a dry run passes for the current schema and source" do
      category = product_import_category(company: company)
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)

      expect(import.approvable?).to be(false)

      Imports::DryRunService.call(import: import)
      import.reload

      expect(import.approvable?).to be(true)
    end

    it "is false when the category schema changed after the dry run" do
      category = product_import_category(company: company)
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)
      Imports::DryRunService.call(import: import)
      import.reload

      category.default_property_mapping.update!(
        metadata: { "properties" => [
          { "key" => "property_string_1", "type" => "string", "name" => "Renamed Property", "validates" => {} }
        ] }
      )

      expect(import.reload.approvable?).to be(false)
    end
  end

  describe "#rollbackable?" do
    it "is true for completed and failed runs only" do
      import = build_import
      import.save!

      expect(import.rollbackable?).to be(false)

      import.update!(workflow_status: :completed)
      expect(import.rollbackable?).to be(true)

      import.update!(workflow_status: :rolled_back)
      expect(import.rollbackable?).to be(false)
    end
  end
end
