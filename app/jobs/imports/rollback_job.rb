# frozen_string_literal: true

# Runs a requested Import rollback (rolling_back → rolled_back). On failure the
# import is restored to the status it had before the rollback so the user can
# retry. Exceptions never re-raise — the outcome is reported through status and
# notification.
module Imports
  class RollbackJob < ApplicationJob
    queue_as :default

    def perform(import_id)
      import = Import.find_by(id: import_id)
      return unless import&.workflow_status_rolling_back?

      result = RollbackService.call(import: import)

      if result[:success]
        finish_rolled_back(import)
      else
        restore_previous_status(import, result[:errors])
      end
    rescue StandardError => e
      restore_previous_status(import, [ "#{e.class}: #{e.message}" ]) if import&.persisted? && import.workflow_status_rolling_back?
    end

    private

    def finish_rolled_back(import)
      import.update!(workflow_status: :rolled_back, rolled_back_at: Time.current)
      ProgressPublisher.publish_finished(import: import)
      notify(
        import,
        name: "Rollback of '#{import.name}' completed",
        description: "#{import.metadata['rollback_processed']} records reverted.",
        severity: :info,
        throttle_key: "import:#{import.id}:rolled_back"
      )
    end

    def restore_previous_status(import, errors)
      previous = import.metadata["rollback_previous_status"].presence || "completed"
      import.update!(workflow_status: previous)
      notify(
        import,
        name: "Rollback of '#{import.name}' failed",
        description: Array(errors).first.to_s,
        severity: :warning,
        throttle_key: "import:#{import.id}:rollback_failed"
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
      Rails.logger.warn("[Imports::RollbackJob] #{Array(result&.[](:errors)).join(', ')}") unless result&.[](:success)
    rescue StandardError => e
      Rails.logger.warn("[Imports::RollbackJob] notify failed: #{e.message}")
    end
  end
end
