# frozen_string_literal: true

# Reverts a completed import from its audit logs, newest first (uuidv7 ids
# sort chronologically, so id DESC ≈ created_at DESC):
#   - action_created logs → destroy the record (dependent cascades run)
#   - action_updated logs → write the recorded previous values back
# Logs are kept as audit; missing records are tolerated, so a re-run — or a
# world changed by hand after the import — never raises. Idempotent.
module CompanyMigrations
  class RollbackService
    def self.call(company_migration:)
      new(company_migration).call
    end

    def initialize(company_migration)
      @migration = company_migration
      @company = company_migration.company
    end

    def call
      total = @migration.company_migration_logs.count
      @migration.update_columns(
        metadata: @migration.metadata.merge("rollback_total" => total, "rollback_processed" => 0)
      )
      ProgressPublisher.publish_progress(company_migration: @migration, phase: "rollback")

      processed = 0

      @migration.company_migration_logs.in_batches(of: MIGRATION_IMPORT_BATCH_SIZE, order: :desc) do |batch|
        batch.group_by(&:record_type).each do |record_type, logs|
          klass = record_type.to_s.safe_constantize
          next if klass.nil?

          revert(klass, logs)
          processed += logs.size
        end

        @migration.update_columns(
          metadata: @migration.metadata.merge("rollback_processed" => processed)
        )
        ProgressPublisher.publish_progress(company_migration: @migration, phase: "rollback")
      end

      { success: true, errors: [] }
    end

    private

    def revert(klass, logs)
      created_ids = logs.select(&:action_created?).filter_map(&:record_id)
      updated_logs = logs.select(&:action_updated?)

      klass.where(company_id: @company.id, id: created_ids).destroy_all if created_ids.any?

      updated_logs.each do |log|
        next if log.previous_state.blank?

        klass.where(company_id: @company.id, id: log.record_id).update_all(log.previous_state)
      end
    end
  end
end
