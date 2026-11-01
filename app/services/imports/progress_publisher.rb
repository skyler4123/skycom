# frozen_string_literal: true

# Publishes Import lifecycle events on the company channel. The show page
# subscribes to both events and filters by payload id (see docs/WEBSOCKET.md).
module Imports
  class ProgressPublisher
    def self.publish_progress(import:, phase: "import")
      data = if phase == "rollback"
        {
          id: import.id,
          phase: "rollback",
          status: import.workflow_status,
          processed_rows: import.metadata["rollback_processed"].to_i,
          total_rows: import.metadata["rollback_total"].to_i,
          created_rows: 0,
          failed_rows: 0
        }
      else
        {
          id: import.id,
          phase: "import",
          status: import.workflow_status,
          processed_rows: import.processed_rows.to_i,
          total_rows: import.total_rows.to_i,
          created_rows: import.created_rows.to_i,
          failed_rows: import.failed_rows.to_i
        }
      end

      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, import.company_id),
        event_key: :import_progress,
        data: data
      )
    end

    def self.publish_finished(import:)
      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, import.company_id),
        event_key: :import_finished,
        data: {
          id: import.id,
          status: import.workflow_status,
          created_rows: import.created_rows.to_i,
          failed_rows: import.failed_rows.to_i
        }
      )
    end
  end
end
