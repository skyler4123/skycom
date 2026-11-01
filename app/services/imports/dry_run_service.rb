# frozen_string_literal: true

require "csv"

# No-write rehearsal of an Import. Validates the CSV header against the exact
# resolved contract, then runs every data row through the real mapper and
# model validations (dynamic property validations included). Stores the result
# plus the schema/source digests that Approve is gated on.
module Imports
  class DryRunService
    def self.call(import:)
      new(import).call
    end

    def initialize(import)
      @import = import
      @company = import.company
    end

    def call
      return store_failure("import is locked") unless @import.workflow_status_draft?
      return store_failure("Upload a CSV file first") if @import.source_file.nil?

      resolver = SchemaResolver.call(
        company: @company,
        target_table: @import.target_table,
        category: @import.category
      )
      return store_failure(resolver[:errors]) unless resolver[:success]

      schema = resolver[:schema]
      header_errors = validate_headers(schema)
      return store_result(schema, header_errors: header_errors) if header_errors.any?

      validate_rows(schema, resolver[:model])
    end

    private

    def validate_headers(schema)
      expected = schema["headers"].map { |entry| entry["header"] }
      actual = header_line

      return [ "file is not valid CSV" ] if actual.nil?

      actual = actual.map { |header| header.to_s.strip }
      errors = []
      errors << "file has no header row" if actual.empty?
      errors << "header row has an empty column name" if actual.any?(&:empty?)

      duplicates = actual.group_by(&:itself).select { |_, entries| entries.size > 1 }.keys
      errors << "duplicate header(s): #{duplicates.join(', ')}" if duplicates.any?

      unknown = actual - expected
      if unknown.any?
        errors << "unknown header(s): #{unknown.join(', ')} — expected: #{expected.join(', ')}"
      end

      errors
    end

    def header_line
      @import.source_file.file.blob.open do |tmp|
        first_line = tmp.gets
        return [] if first_line.nil?

        CSV.parse_line(first_line.sub(/\A\uFEFF/, ""))
      end
    rescue CSV::MalformedCSVError, ArgumentError, Encoding::InvalidByteSequenceError
      nil
    end

    def validate_rows(schema, model)
      mapper = RowMapper.new(company: @company, schema: schema, model: model)
      base_attrs = base_attrs(schema)
      valid_rows = 0
      invalid_rows = 0
      row_errors = []
      total_rows = 0

      @import.source_file.file.blob.open do |tmp|
        CSV.foreach(tmp, headers: true, encoding: "bom|utf-8") do |csv_row|
          total_rows += 1
          mapped = mapper.map(csv_row)
          record = model.new(mapped[:attrs].merge(base_attrs))
          record.skip_property_auto_population = true
          record.valid?

          errors = mapped[:errors] + record.errors.full_messages

          if errors.empty?
            valid_rows += 1
          else
            invalid_rows += 1
            if row_errors.size < IMPORT_ERROR_SAMPLES_LIMIT
              row_errors << { "row" => total_rows, "errors" => errors.first(5) }
            end
          end
        end
      end

      passed = invalid_rows.zero? && total_rows.positive?

      result = result_hash(schema, total_rows: total_rows, valid_rows: valid_rows,
                                   invalid_rows: invalid_rows, header_errors: [],
                                   row_errors: row_errors, passed: passed)

      @import.update!(
        schema_snapshot: schema,
        dry_run_result: result,
        total_rows: total_rows
      )

      {
        success: passed,
        errors: passed ? [] : [ "#{invalid_rows} row(s) failed validation" ],
        result: result
      }
    end

    def store_failure(errors)
      result = result_hash(nil, total_rows: @import.total_rows.to_i, valid_rows: 0,
                                 invalid_rows: 0, header_errors: Array(errors),
                                 row_errors: [], passed: false)
      @import.update!(dry_run_result: result, schema_snapshot: {})

      { success: false, errors: Array(errors), result: result }
    end

    def store_result(schema, header_errors:)
      result = result_hash(schema, total_rows: @import.total_rows.to_i, valid_rows: 0,
                                   invalid_rows: 0, header_errors: header_errors,
                                   row_errors: [], passed: false)
      @import.update!(schema_snapshot: schema, dry_run_result: result)

      { success: false, errors: header_errors, result: result }
    end

    def result_hash(schema, total_rows:, valid_rows:, invalid_rows:, header_errors:, row_errors:, passed:)
      {
        "passed" => passed,
        "checked_at" => Time.current.iso8601,
        "schema_digest" => schema&.dig("digest"),
        "source_digest" => @import.source_digest,
        "total_rows" => total_rows,
        "valid_rows" => valid_rows,
        "invalid_rows" => invalid_rows,
        "header_errors" => header_errors,
        "row_errors" => row_errors
      }
    end

    def base_attrs(schema)
      {
        "company_id" => @company.id,
        "category_id" => schema["category_id"],
        "property_mapping_id" => @import.category.default_property_mapping.id
      }
    end
  end
end
