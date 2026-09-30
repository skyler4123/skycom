class CreateCalendarSyncLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_sync_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_sync_connection, null: true, foreign_key: true, type: :uuid

      t.string   :provider, null: false

      # push | pull | bidirectional — see CALENDAR_SYNC_DIRECTIONS.
      t.integer  :direction, null: false, default: 0

      # 'CalendarEvent' | 'CalendarProcedure' | 'CalendarPractitioner' | ...
      t.string   :entity_type
      t.uuid     :entity_id
      t.string   :external_id

      # success | error | partial — see CALENDAR_SYNC_LOG_STATUSES.
      t.integer  :status, null: false, default: 0

      t.jsonb    :request_payload, default: {}
      t.jsonb    :response_payload, default: {}
      t.text     :error_message
      t.integer  :duration_ms

      t.timestamps
    end

    add_index :calendar_sync_logs, [ :company_id, :provider, :created_at ],
      name: "idx_calendar_sync_logs_company_provider"
    add_index :calendar_sync_logs, [ :entity_type, :entity_id ],
      name: "idx_calendar_sync_logs_entity"
  end
end
