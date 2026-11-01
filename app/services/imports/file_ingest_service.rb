# frozen_string_literal: true

require "csv"
require "digest"

# Stores a single CSV source file for a draft Import: validates extension/size,
# counts data rows, attaches a StoredFile in the import's folder, and records
# filename/size/digest. Re-uploading replaces the previous file and invalidates
# the dry run (the approved result must match the exact bytes validated).
module Imports
  class FileIngestService
    def self.call(import:, file:, company:)
      new(import: import, file: file, company: company).call
    end

    def initialize(import:, file:, company:)
      @import = import
      @file = file
      @company = company
    end

    def call
      return failure("import is locked") unless @import.workflow_status_draft?
      return failure("file is required") if @file.blank?
      return failure("file must be a CSV") unless csv_file?
      return failure("file is too big (max #{IMPORT_MAX_FILE_BYTES / 1.megabyte}MB)") if @file.size.to_i > IMPORT_MAX_FILE_BYTES

      content = read_content
      return failure("file is empty") if content.blank?

      row_count = data_row_count(content)
      return failure("file is not valid CSV") if row_count.nil?
      return failure("file has no data rows") if row_count.zero?
      return failure("file has more than #{IMPORT_MAX_ROWS} rows") if row_count > IMPORT_MAX_ROWS

      persist!(content, row_count)
      { success: true, errors: [], row_count: row_count }
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def csv_file?
      name = @file.original_filename.to_s
      @file.content_type.to_s.include?("csv") || File.extname(name).downcase == ".csv"
    end

    def read_content
      @file.read.to_s.dup.force_encoding(Encoding::UTF_8).sub(/\A\uFEFF/, "")
    end

    def data_row_count(content)
      CSV.parse(content, headers: true).size
    rescue CSV::MalformedCSVError, ArgumentError, Encoding::InvalidByteSequenceError
      nil
    end

    def persist!(content, row_count)
      name = File.basename(@file.original_filename.to_s.presence || "source.csv")[0, 255]

      Import.transaction do
        @import.source_file&.destroy!

        stored_file = @import.build_source_file(
          company: @company,
          folder: @import.folder,
          name: name,
          metadata: { "row_count" => row_count }
        )
        stored_file.file.attach(
          io: StringIO.new(content),
          filename: name,
          content_type: "text/csv"
        )
        stored_file.save!

        @import.update!(
          source_filename: name,
          source_file_size: content.bytesize,
          source_digest: Digest::SHA256.hexdigest(content),
          total_rows: row_count,
          dry_run_result: nil,
          schema_snapshot: {},
          error_samples: []
        )
      end
    end

    def failure(message)
      { success: false, errors: Array(message), row_count: 0 }
    end
  end
end
