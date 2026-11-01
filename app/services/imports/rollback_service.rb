# frozen_string_literal: true

# Reverts a completed (or partially failed) Import by replaying its audit log
# newest-first and destroying only the records this import created. Missing
# records are tolerated, so a re-run — or a world changed by hand after the
# import — never raises. Logs are kept as audit.
module Imports
  class RollbackService
    def self.call(import:)
      new(import).call
    end

    def initialize(import)
      @import = import
      @company = import.company
      @metadata = import.metadata.dup
    end

    def call
      @metadata["rollback_total"] = @import.import_logs.count
      @metadata["rollback_processed"] = 0
      @import.update_columns(metadata: @metadata)
      ProgressPublisher.publish_progress(import: @import, phase: "rollback")

      processed = 0

      @import.import_logs.in_batches(of: IMPORT_BATCH_SIZE, order: :desc) do |batch|
        batch.group_by(&:record_type).each do |record_type, logs|
          klass = record_type.safe_constantize
          next if klass.nil?

          ids = logs.map(&:record_id)
          klass.where(company_id: @company.id, id: ids).destroy_all
        end

        processed += batch.size
        @metadata["rollback_processed"] = processed
        @import.update_columns(metadata: @metadata)
        ProgressPublisher.publish_progress(import: @import, phase: "rollback")
      end

      { success: true, errors: [] }
    end
  end
end
