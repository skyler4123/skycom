# frozen_string_literal: true

require "csv"

# Streams every not-yet-completed chunk through the row mapper + model and
# persists valid rows with a batched upsert, writing one audit log per
# created/changed record so RollbackService can revert the run. Chunk-level
# counters are the source of truth (resumed chunks reset theirs), and the
# migration counters are recomputed after every batch.
#
# Semantics that matter:
# - Rows are validated on a throwaway instance; only mapped/defaulted attrs
#   are persisted, so updates never null out unmapped columns.
# - On updates, a blank mapped value keeps the existing DB value (backfill).
# - Upsert conflicts on [company_id, external_id] (unique_by index name);
#   logs dedupe on [migration, record_type, record_id] keeping the earliest.
#
# v1 is single-target (customers proven end-to-end) — Preflight refuses
# configs with more than one target before any work happens.
module CompanyMigrations
  class ImportService
    LOG_UNIQUE_INDEX = "idx_company_migration_logs_unique_record"

    def self.call(company_migration:)
      new(company_migration).call
    end

    def initialize(company_migration)
      @migration = company_migration
      @company = company_migration.company
      @config = company_migration.config
      @samples = company_migration.error_samples || []
      @samples_dirty = false
    end

    def call
      preflight = Preflight.call(company_migration: @migration)
      return { success: false, errors: preflight[:errors] } unless preflight[:success]

      target = preflight[:target]
      category_result = CategoryResolver.call(
        company: @company,
        resource: target["resource"],
        category_config: target["category"]
      )
      return { success: false, errors: category_result[:errors] } unless category_result[:success]

      @model = preflight[:model]
      @identity_index_name = preflight[:identity_index_name]
      @mapper = RowMapper.new(target: target, company: @company)
      @identity_column = target.dig("identity", "column")
      @mapped_columns = mapped_columns(target)
      @resource = target["resource"]
      @base_attrs = {
        "company_id" => @company.id,
        "category_id" => category_result[:category].id,
        "property_mapping_id" => category_result[:category].default_property_mapping.id
      }

      @migration.ordered_chunks.each do |chunk|
        import_chunk(chunk) unless chunk.import_status == "completed"
      end

      { success: true, errors: [] }
    end

    private

    def import_chunk(chunk)
      chunk.processed_rows = 0
      chunk.created_rows = 0
      chunk.updated_rows = 0
      chunk.failed_rows = 0

      buffer = []
      row_number = 0

      chunk.file.blob.open do |tmp|
        CSV.foreach(tmp, headers: true, encoding: "bom|utf-8") do |csv_row|
          buffer << csv_row

          if buffer.size >= MIGRATION_IMPORT_BATCH_SIZE
            process_batch(chunk, buffer, row_number)
            row_number += buffer.size
            buffer = []
          end
        end

        process_batch(chunk, buffer, row_number) if buffer.any?
      end

      chunk.import_status = "completed"
      flush(chunk)
    end

    def process_batch(chunk, batch, first_row_number)
      upsertable = []

      batch.each_with_index do |csv_row, index|
        source_row = first_row_number + index + 1
        mapped = @mapper.map(csv_row)
        external_id = csv_row[@identity_column].to_s

        if mapped[:errors].any?
          record_failure(chunk, source_row, mapped[:errors])
          next
        end

        if external_id.blank?
          record_failure(chunk, source_row, [ "#{@identity_column}: identity value is required" ])
          next
        end

        attrs = mapped[:attrs].merge(@base_attrs).merge("external_id" => external_id)
        record = @model.new(attrs)

        unless record.valid?
          record_failure(chunk, source_row, record.errors.full_messages)
          next
        end

        upsertable << { attrs: attrs, external_id: external_id, source_row: source_row }
      end

      persist_batch(chunk, upsertable) if upsertable.any?
      flush(chunk)
    end

    def persist_batch(chunk, rows)
      # Postgres cannot update the same conflict target twice in one statement.
      rows = rows.each_with_object({}) { |row, unique| unique[row[:external_id]] = row }.values
      existing = existing_records(rows.map { |row| row[:external_id] })

      result = @model.upsert_all(
        upsert_attributes(rows, existing),
        unique_by: @identity_index_name,
        returning: %w[id external_id],
        record_timestamps: true
      )
      returned = result.to_a.index_by { |row| row["external_id"] }

      logs = []
      created = 0
      updated = 0

      rows.each do |row|
        prior = existing[row[:external_id]]

        if prior
          previous_state = changed_previous_state(row[:attrs], prior)
          next if previous_state.empty?

          updated += 1
          logs << log_row(row, returned[row[:external_id]], action: 1, previous_state: previous_state)
        else
          created += 1
          logs << log_row(row, returned[row[:external_id]], action: 0, previous_state: {})
        end
      end

      if logs.any?
        CompanyMigrationLog.insert_all(
          logs,
          unique_by: LOG_UNIQUE_INDEX,
          record_timestamps: true
        )
      end

      chunk.processed_rows = chunk.processed_rows.to_i + rows.size
      chunk.created_rows = chunk.created_rows.to_i + created
      chunk.updated_rows = chunk.updated_rows.to_i + updated
    end

    def existing_records(external_ids)
      @model
        .where(company_id: @company.id, external_id: external_ids)
        .pluck(:id, :external_id, *@mapped_columns)
        .each_with_object({}) do |row, hash|
          id, external_id, *values = row
          hash[external_id] = { id: id, previous: @mapped_columns.zip(values).to_h }
        end
    end

    def upsert_attributes(rows, existing)
      rows.map do |row|
        attrs = row[:attrs].dup
        prior = existing[row[:external_id]]

        @mapped_columns.each do |column|
          next if attrs.key?(column)

          attrs[column] = prior ? prior[:previous][column] : nil
        end

        attrs
      end
    end

    def changed_previous_state(attrs, prior)
      @mapped_columns.each_with_object({}) do |column, diff|
        old_value = prior[:previous][column]
        new_value = attrs.key?(column) ? attrs[column] : old_value

        diff[column] = old_value if new_value != old_value
      end
    end

    def log_row(row, returned, action:, previous_state:)
      {
        company_migration_id: @migration.id,
        company_id: @company.id,
        record_type: @model.name,
        record_id: returned && returned["id"],
        action: action,
        previous_state: previous_state,
        resource: @resource,
        source_row: row[:source_row]
      }
    end

    def record_failure(chunk, source_row, errors)
      chunk.processed_rows = chunk.processed_rows.to_i + 1
      chunk.failed_rows = chunk.failed_rows.to_i + 1

      return if @samples.size >= MIGRATION_ERROR_SAMPLES_LIMIT

      @samples << { "source_row" => source_row, "chunk_index" => chunk.chunk_index, "errors" => errors }
      @samples_dirty = true
    end

    def flush(chunk)
      chunk.save! if chunk.changed?
      @migration.recompute_counters!
      persist_samples
      ProgressPublisher.publish_progress(company_migration: @migration)
    end

    def persist_samples
      return unless @samples_dirty

      @migration.update_columns(metadata: @migration.metadata.merge("error_samples" => @samples))
      @samples_dirty = false
    end

    def mapped_columns(target)
      columns = (target["columns"] || {}).values.filter_map { |mapping| mapping["target"] if mapping.is_a?(Hash) }
      columns += (target["defaults"] || {}).keys

      has_metadata = columns.any? { |column| column.start_with?("metadata.") }
      columns = columns.reject { |column| column.start_with?("metadata.") }
      columns << "metadata" if has_metadata
      columns.uniq
    end
  end
end
