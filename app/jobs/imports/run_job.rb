# frozen_string_literal: true

# Runs an approved Import: statuses are owned here (processing → completed |
# failed), the engine work is Imports::RunService, and the employee who created
# the import gets exactly one notification per outcome. Exceptions mark the
# import failed instead of re-raising — a failed run is terminal and cleaned up
# with Rollback.
module Imports
  class RunJob < ApplicationJob
    queue_as :default

    def perform(import_id)
      import = Import.find_by(id: import_id)
      return unless import&.workflow_status_approved?

      import.update!(workflow_status: :processing)

      result = RunService.call(import: import)

      if result[:success]
        finish_completed(import)
      else
        finish_failed(import, result[:errors])
      end
    rescue StandardError => e
      finish_failed(import, [ "#{e.class}: #{e.message}" ]) if import&.persisted? && import.workflow_status_processing?
    end

    private

    def finish_completed(import)
      import.update!(workflow_status: :completed, completed_at: Time.current)
      ProgressPublisher.publish_finished(import: import)
      notify(
        import,
        name: "Import '#{import.name}' finished",
        description: "#{import.created_rows} of #{import.total_rows} rows imported (#{import.failed_rows} failed).",
        severity: :info,
        throttle_key: "import:#{import.id}:finished"
      )
    end

    def finish_failed(import, errors)
      samples = Array(import.error_samples).dup
      errors = Array(errors)
      samples << { "errors" => errors.first(5) } if samples.size < IMPORT_ERROR_SAMPLES_LIMIT && errors.any?

      import.update!(
        workflow_status: :failed,
        error_samples: samples
      )
      ProgressPublisher.publish_finished(import: import)
      notify(
        import,
        name: "Import '#{import.name}' failed",
        description: errors.first.to_s,
        severity: :warning,
        throttle_key: "import:#{import.id}:failed"
      )
    end

    def notify(import, name:, description:, severity:, throttle_key:)
      result = NotifyCreatorService.call(
        import: import,
        name: name,
        description: description,
        severity: severity,
        throttle_key: throttle_key
      )
      Rails.logger.warn("[Imports::RunJob] #{Array(result&.[](:errors)).join(', ')}") unless result&.[](:success)
    rescue StandardError => e
      Rails.logger.warn("[Imports::RunJob] notify failed: #{e.message}")
    end
  end
end
