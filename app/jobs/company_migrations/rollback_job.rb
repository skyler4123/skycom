# frozen_string_literal: true

# Runs a requested rollback (rolling_back → rolled_back). A failure returns
# the migration to completed so the owner can retry. Exceptions never
# re-raise — the outcome is reported through status + notification.
module CompanyMigrations
  class RollbackJob < ApplicationJob
    queue_as :default

    def perform(company_migration_id)
      migration = CompanyMigration.find_by(id: company_migration_id)
      return unless migration&.workflow_status_rolling_back?

      result = RollbackService.call(company_migration: migration)

      if result[:success]
        finish_rolled_back(migration)
      else
        finish_failed(migration, result[:errors])
      end
    rescue StandardError => e
      finish_failed(migration, [ "#{e.class}: #{e.message}" ]) if migration&.persisted? && migration.workflow_status_rolling_back?
    end

    private

    def finish_rolled_back(migration)
      migration.update!(workflow_status: :rolled_back, rolled_back_at: Time.current)
      ProgressPublisher.publish_finished(company_migration: migration)
      notify(
        migration,
        name: "Rollback of '#{migration.name}' completed",
        description: "#{migration.rollback_processed} records reverted.",
        severity: :info,
        throttle_key: "company_migration:#{migration.id}:rolled_back"
      )
    end

    def finish_failed(migration, errors)
      migration.update!(workflow_status: :completed)
      notify(
        migration,
        name: "Rollback of '#{migration.name}' failed",
        description: errors.first.to_s,
        severity: :warning,
        throttle_key: "company_migration:#{migration.id}:rollback_failed"
      )
    end

    def notify(migration, name:, description:, severity:, throttle_key:)
      result = NotifyOwnerService.call(
        company: migration.company,
        name: name,
        description: description,
        severity: severity,
        throttle_key: throttle_key
      )
      Rails.logger.warn("[CompanyMigrations::RollbackJob] #{Array(result[:errors]).join(', ')}") unless result&.[](:success)
    rescue StandardError => e
      Rails.logger.warn("[CompanyMigrations::RollbackJob] notify failed: #{e.message}")
    end
  end
end
