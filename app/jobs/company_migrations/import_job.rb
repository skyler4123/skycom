# frozen_string_literal: true

# Runs an approved CompanyMigration: statuses are owned here (processing →
# completed | failed), the engine work is ImportService, and the owner gets
# exactly one notification per outcome. Exceptions mark the migration failed
# instead of re-raising — retrying is the owner's explicit re-approve.
module CompanyMigrations
  class ImportJob < ApplicationJob
    queue_as :default

    def perform(company_migration_id)
      migration = CompanyMigration.find_by(id: company_migration_id)
      return unless migration&.workflow_status_approved?

      migration.update!(workflow_status: :processing)

      result = ImportService.call(company_migration: migration)

      if result[:success]
        finish_completed(migration)
      else
        finish_failed(migration, result[:errors])
      end
    rescue StandardError => e
      finish_failed(migration, [ "#{e.class}: #{e.message}" ]) if migration&.persisted? && migration.workflow_status_processing?
    end

    private

    def finish_completed(migration)
      migration.update!(workflow_status: :completed, completed_at: Time.current)
      ProgressPublisher.publish_finished(company_migration: migration)
      notify(
        migration,
        name: "Data import '#{migration.name}' finished",
        description: "#{migration.created_rows} of #{migration.total_rows} rows imported (#{migration.failed_rows} failed).",
        severity: :info,
        throttle_key: "company_migration:#{migration.id}:finished"
      )
    end

    def finish_failed(migration, errors)
      samples = Array(migration.error_samples)
      samples << { "errors" => errors } if samples.size < MIGRATION_ERROR_SAMPLES_LIMIT

      migration.update!(
        workflow_status: :failed,
        metadata: migration.metadata.merge("error_samples" => samples)
      )
      ProgressPublisher.publish_finished(company_migration: migration)
      notify(
        migration,
        name: "Data import '#{migration.name}' failed",
        description: errors.first.to_s,
        severity: :warning,
        throttle_key: "company_migration:#{migration.id}:failed"
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
      Rails.logger.warn("[CompanyMigrations::ImportJob] #{Array(result[:errors]).join(', ')}") unless result&.[](:success)
    rescue StandardError => e
      Rails.logger.warn("[CompanyMigrations::ImportJob] notify failed: #{e.message}")
    end
  end
end
