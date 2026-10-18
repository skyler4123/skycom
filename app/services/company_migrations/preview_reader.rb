# frozen_string_literal: true

require "csv"

# Raw preview of chunk 0 for the show page: BOM-stripped headers plus the
# first MIGRATION_PREVIEW_ROW_LIMIT data rows, exactly as they appear in the
# uploaded file.
module CompanyMigrations
  class PreviewReader
    def self.call(company_migration:)
      new(company_migration).call
    end

    def initialize(company_migration)
      @migration = company_migration
    end

    def call
      chunk = @migration.ordered_chunks.first
      return { headers: [], rows: [] } if chunk.nil? || !chunk.file.attached?

      headers = nil
      rows = []

      chunk.file.blob.open do |tmp|
        CSV.foreach(tmp, headers: true, encoding: "bom|utf-8") do |row|
          headers ||= row.headers
          rows << row.fields
          break if rows.size >= MIGRATION_PREVIEW_ROW_LIMIT
        end

        if headers.nil?
          tmp.rewind
          first_line = tmp.gets
          headers = first_line ? CSV.parse_line(first_line.sub(/\A\uFEFF/, "")) : []
        end
      end

      { headers: headers || [], rows: rows }
    end
  end
end
