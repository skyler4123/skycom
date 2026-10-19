# frozen_string_literal: true

require "csv"

# Shared fixtures for CompanyMigration specs: the normative customers config
# (bound to faker/files/customers-10.csv) and a chunk uploader that mirrors
# what Companies::CompanyMigrationsController#chunks persists.
module CompanyMigrationsHelper
  def customers_migration_config
    {
      "version" => 1,
      "source" => { "has_header" => true },
      "targets" => [
        {
          "resource" => "customers",
          "identity" => { "column" => "Customer Id" },
          "category" => {
            "mode" => "create_or_reuse",
            "name" => "Imported Customers",
            "properties" => { "property_string_1" => "Company", "property_string_2" => "City" },
            "visible_columns" => %w[name email property_string_1 property_string_2]
          },
          "columns" => {
            "First Name" => { "target" => "name" },
            "Email" => { "target" => "email" },
            "Phone 1" => { "target" => "phone_number" },
            "Company" => { "target" => "property_string_1" },
            "City" => { "target" => "property_string_2" },
            "Website" => { "target" => "metadata.website" }
          },
          "defaults" => { "business_type" => "individual", "country" => "us", "currency" => "usd", "lifecycle_status" => "active" }
        }
      ]
    }
  end

  # chunks: array of CSV strings or Pathnames (a file path is read as-is).
  def create_migration_with_chunks(company:, chunks:, config:, name: nil)
    migration_name = name || "Import #{SecureRandom.hex(4)}"
    migration = CompanyMigration.create!(
      company: company,
      folder: Folder.create!(company: company, name: migration_name),
      name: migration_name,
      workflow_status: :draft,
      migration_mapping_config: config
    )

    header_json = nil

    chunks.each_with_index do |chunk, index|
      content = chunk.is_a?(Pathname) ? chunk.read : chunk.to_s
      clean = content.sub(/\A\uFEFF/, "")
      header_json ||= CSV.parse_line(clean.lines.first)&.to_json
      rows = CSV.parse(clean, headers: true).size

      stored_file = migration.stored_files.new(
        company: company,
        folder: migration.folder,
        name: format("part-%03d.csv", index),
        metadata: { "chunk_index" => index, "row_count" => rows, "import_status" => "uploaded" }
      )
      stored_file.file.attach(
        io: StringIO.new(content.b),
        filename: format("part-%03d.csv", index),
        content_type: "text/csv"
      )
      stored_file.save!
    end

    migration.update!(metadata: migration.metadata.merge("source_header" => header_json)) if header_json
    migration.recompute_counters!
    migration.reload
  end
end

RSpec.configure do |config|
  config.include CompanyMigrationsHelper
end
