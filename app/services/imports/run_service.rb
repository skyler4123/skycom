# frozen_string_literal: true

require "csv"

# Executes an approved Import: every valid CSV row creates a new record and one
# ImportLog audit row, so RollbackService can destroy exactly those records.
# Invalid rows are counted and sampled, and never abort the run; unexpected
# errors propagate to Imports::RunJob, which owns the failed status.
module Imports
  class RunService
    def self.call(import:)
      new(import).call
    end

    def initialize(import)
      @import = import
      @company = import.company
      @samples = []
      @log_rows = []
    end

    def call
      unless @import.workflow_status_approved? || @import.workflow_status_processing?
        return failure("Import is not approved")
      end
      return failure("Import is already running") if @import.processed_rows.to_i.positive?

      resolver = SchemaResolver.call(
        company: @company,
        target_table: @import.target_table,
        category: @import.category
      )
      return failure(resolver[:errors]) unless resolver[:success]

      schema = resolver[:schema]
      return failure("Run a passing dry run before approving") unless @import.dry_run_passed_for?(schema)

      @model = resolver[:model]
      @schema = schema
      @mapper = RowMapper.new(company: @company, schema: schema, model: @model)
      @base_attrs = base_attrs(schema)
      @processed = 0
      @created = 0
      @failed = 0

      @import.update_columns(
        processed_rows: 0,
        created_rows: 0,
        failed_rows: 0,
        error_samples: []
      )

      @import.source_file.file.blob.open do |tmp|
        CSV.foreach(tmp, headers: true, encoding: "bom|utf-8") do |csv_row|
          process_row(csv_row)
          flush if (@processed % IMPORT_BATCH_SIZE).zero?
        end
      end

      flush
      { success: true, errors: [] }
    end

    private

    def process_row(csv_row)
      @processed += 1
      mapped = @mapper.map(csv_row)

      if mapped[:errors].any?
        record_failure(mapped[:errors])
        return
      end

      record = @model.new(mapped[:attrs].merge(@base_attrs))
      record.skip_property_auto_population = true

      begin
        record.save!
        @created += 1
        @log_rows << log_row(record, @processed)
      rescue ActiveRecord::RecordInvalid => e
        record_failure(e.record.errors.full_messages)
      rescue ActiveRecord::InvalidForeignKey, ActiveRecord::StatementInvalid => e
        record_failure([ e.message ])
      end
    end

    def log_row(record, source_row)
      {
        import_id: @import.id,
        company_id: @company.id,
        record_type: @model.name,
        record_id: record.id,
        action: 0,
        source_row: source_row,
        previous_state: {},
        resource: @schema["target_table"]
      }
    end

    def record_failure(errors)
      @failed += 1
      return if @samples.size >= IMPORT_ERROR_SAMPLES_LIMIT

      @samples << { "row" => @processed, "errors" => Array(errors).first(5) }
    end

    def flush
      if @log_rows.any?
        ImportLog.insert_all(@log_rows, record_timestamps: true)
        @log_rows = []
      end

      @import.update_columns(
        processed_rows: @processed,
        created_rows: @created,
        failed_rows: @failed,
        error_samples: @samples
      )
      ProgressPublisher.publish_progress(import: @import)
    end

    def base_attrs(schema)
      {
        "company_id" => @company.id,
        "category_id" => schema["category_id"],
        "property_mapping_id" => @import.category.default_property_mapping.id
      }
    end

    def failure(message)
      { success: false, errors: Array(message) }
    end
  end
end
