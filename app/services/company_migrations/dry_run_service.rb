# frozen_string_literal: true

# No-write rehearsal of an import: runs the first MIGRATION_PREVIEW_ROW_LIMIT
# data rows of chunk 0 through the real mapper + model (dynamic property
# validations included) and records the outcome — plus the config digest it
# validated — on the migration. Approve is gated on this result.
#
# Category resolution is config-level prep (idempotent, reuses the seeding
# services); target rows are never written.
module CompanyMigrations
  class DryRunService
    def self.call(company_migration:)
      new(company_migration).call
    end

    def initialize(company_migration)
      @migration = company_migration
      @company = company_migration.company
      @config = company_migration.config
    end

    def call
      preflight = Preflight.call(company_migration: @migration)
      return stored_failure(preflight[:errors]) unless preflight[:success]

      target = preflight[:target]
      category_result = CategoryResolver.call(
        company: @company,
        resource: target["resource"],
        category_config: target["category"]
      )
      return stored_failure(category_result[:errors]) unless category_result[:success]

      category = category_result[:category]
      model = preflight[:model]
      mapper = RowMapper.new(target: target, company: @company)
      identity_column = target.dig("identity", "column")

      rows = []
      created = 0
      updated = 0

      sample_rows(@migration.ordered_chunks.first).each_with_index do |csv_row, index|
        mapped = mapper.map(csv_row)
        external_id = csv_row[identity_column].to_s
        action = existing_external_id?(model, external_id) ? "update" : "create"

        attrs = mapped[:attrs].merge(
          "company_id" => @company.id,
          "category_id" => category.id,
          "property_mapping_id" => category.default_property_mapping.id
        )
        record = model.new(attrs)
        record.valid?
        row_errors = mapped[:errors] + record.errors.full_messages

        rows << { "row" => index + 1, "action" => action, "values" => mapped[:attrs], "errors" => row_errors }

        next if row_errors.any?

        if action == "create"
          created += 1
        else
          updated += 1
        end
      end

      result = {
        "passed" => rows.all? { |row| row["errors"].empty? },
        "checked_at" => Time.current.iso8601,
        "config_digest" => @config.digest,
        "sample_size" => rows.size,
        "created" => created,
        "updated" => updated,
        "rows" => rows,
        "errors" => []
      }

      @migration.update!(dry_run_result: result)
      { success: result["passed"], errors: [], result: result }
    end

    private

    def stored_failure(errors)
      result = {
        "passed" => false,
        "checked_at" => Time.current.iso8601,
        "config_digest" => @config.digest,
        "sample_size" => 0,
        "created" => 0,
        "updated" => 0,
        "rows" => [],
        "errors" => errors
      }

      @migration.update!(dry_run_result: result)
      { success: false, errors: errors, result: result }
    end

    def sample_rows(chunk)
      rows = []

      chunk.file.blob.open do |tmp|
        CSV.foreach(tmp, headers: true, encoding: "bom|utf-8") do |row|
          rows << row
          break if rows.size >= MIGRATION_PREVIEW_ROW_LIMIT
        end
      end

      rows
    end

    def existing_external_id?(model, external_id)
      return false if external_id.blank?

      model.where(company_id: @company.id, external_id: external_id).exists?
    end
  end
end
