# frozen_string_literal: true

# Publishes CompanyMigration lifecycle events on the company channel. The
# show page subscribes to both events and filters by payload id (see
# docs/WEBSOCKET.md — event registry lives in config/initializers/websocket.rb).
module CompanyMigrations
  class ProgressPublisher
    def self.publish_progress(company_migration:, phase: "import")
      migration = company_migration

      data = if phase == "rollback"
        {
          id: migration.id,
          phase: "rollback",
          status: migration.workflow_status,
          processed_rows: migration.rollback_processed.to_i,
          total_rows: migration.rollback_total.to_i,
          created_rows: 0,
          updated_rows: 0,
          failed_rows: 0
        }
      else
        {
          id: migration.id,
          phase: "import",
          status: migration.workflow_status,
          processed_rows: migration.processed_rows,
          total_rows: migration.total_rows,
          created_rows: migration.created_rows,
          updated_rows: migration.updated_rows,
          failed_rows: migration.failed_rows
        }
      end

      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, migration.company_id),
        event_key: :company_migration_progress,
        data: data
      )
    end

    def self.publish_finished(company_migration:)
      migration = company_migration

      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, migration.company_id),
        event_key: :company_migration_finished,
        data: {
          id: migration.id,
          status: migration.workflow_status,
          created_rows: migration.created_rows,
          updated_rows: migration.updated_rows,
          failed_rows: migration.failed_rows
        }
      )
    end
  end
end
