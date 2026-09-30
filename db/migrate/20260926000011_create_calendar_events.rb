class CreateCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_events, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_procedure, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      # What generated this booking (Order / Reservation), or nil for a
      # walk-in booked straight on the board.
      t.string   :source_type
      t.uuid     :source_id

      t.string   :title
      t.text     :description
      t.text     :notes
      t.string   :location_note

      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string   :timezone, null: false, default: "UTC"
      t.boolean  :all_day, null: false, default: false

      t.integer  :status, null: false, default: 0
      t.datetime :confirmed_at
      t.datetime :cancelled_at
      t.string   :cancellation_reason

      # --- External Sync (future Cal.com / Google / Outlook) ---
      t.string   :external_provider
      t.string   :external_id
      t.string   :external_etag
      t.integer  :sync_status, null: false, default: 0
      t.datetime :last_synced_at
      t.text     :last_sync_error

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    # Range scan for the board + the overlap probe behind conflict detection.
    add_index :calendar_events, [ :company_id, :starts_at, :ends_at ],
      name: "idx_calendar_events_company_window"
    add_index :calendar_events, [ :calendar_procedure_id, :starts_at ]
    add_index :calendar_events, [ :company_id, :status ]
    add_index :calendar_events, [ :source_type, :source_id ]
    add_index :calendar_events, [ :external_provider, :external_id ]
  end
end
