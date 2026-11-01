# frozen_string_literal: true

require "csv"
require "digest"

# Shared fixtures for Import specs: a real products category with named dynamic
# properties, CSV generation, and a file uploader that mirrors
# Imports::FileIngestService (so specs never depend on the controller).
module ImportsHelper
  DEFAULT_PROPERTIES = {
    property_string_1: "Skin Type Suitability",
    property_integer_1: "Volume (ml)"
  }.freeze

  def product_import_category(company:, name: nil, properties: nil)
    Seed::CategoryService.create(
      company: company,
      name: name || "Imported Products #{SecureRandom.hex(3)}",
      resource_name: "products",
      properties: properties || DEFAULT_PROPERTIES
    )
  end

  def import_csv(headers:, rows:)
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  def product_import_csv
    import_csv(
      headers: [ "name", "business_type", "Skin Type Suitability", "Volume (ml)" ],
      rows: [
        [ "Imported Serum", "physical", "Oily", "30" ],
        [ "Imported Cream", "physical", "Dry", "50" ]
      ]
    )
  end

  def owner_of(company)
    company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
  end

  # Builds a valid Product directly in a category. The product factory's
  # initialize_with (Seed::ProductService) cannot take a category override, so
  # specs that need a specific category must build the record explicitly.
  def create_product_in_category(company:, category:, name: "Product #{SecureRandom.hex(3)}")
    Product.create!(
      company: company,
      category: category,
      property_mapping: category.default_property_mapping,
      name: name,
      business_type: :physical
    )
  end

  # Creates a draft import with a target table/category and an uploaded CSV.
  def create_import_with_file(company:, category:, csv:, name: nil, creator: nil, target_table: nil)
    creator ||= owner_of(company)
    import = create(
      :import,
      company: company,
      name: name || "Import #{SecureRandom.hex(4)}",
      creator: creator
    )
    import.update!(
      target_table: target_table || category.resource_name,
      target_model: IMPORTABLE_RESOURCES[target_table || category.resource_name],
      category: category
    )
    upload_import_file(import, csv)
    import.reload
  end

  def upload_import_file(import, csv, filename: "source.csv")
    row_count = CSV.parse(csv, headers: true).size
    stored_file = import.build_source_file(
      company: import.company,
      folder: import.folder,
      name: filename,
      metadata: { "row_count" => row_count }
    )
    stored_file.file.attach(io: StringIO.new(csv), filename: filename, content_type: "text/csv")
    stored_file.save!

    import.update!(
      source_filename: filename,
      source_file_size: csv.bytesize,
      source_digest: Digest::SHA256.hexdigest(csv),
      total_rows: row_count,
      dry_run_result: nil,
      schema_snapshot: {},
      error_samples: []
    )
    import.reload
  end
end

RSpec.configure do |config|
  config.include ImportsHelper
end
