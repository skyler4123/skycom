class CreateCalendarTables < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_integrations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :accountable, polymorphic: true, null: false, type: :uuid
      t.string :provider, null: false, default: "cal_com"
      t.string :external_user_id
      t.string :access_token
      t.string :refresh_token
      t.integer :status, default: 0, null: false

      # --- System Fields ---
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :calendar_integrations,
      [ :company_id, :accountable_type, :accountable_id, :provider ],
      unique: true,
      name: "idx_calendar_integrations_unique_provider"

    create_table :calendar_events, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_integration, null: true, foreign_key: true, type: :uuid
      t.references :schedulable, polymorphic: true, null: true, type: :uuid

      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :time_zone, default: "UTC"
      t.integer :status, default: 0, null: false

      # --- System Fields ---
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :calendar_events, [ :starts_at, :ends_at ]

    create_table :calendar_sync_mappings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_event, null: false, foreign_key: true, type: :uuid
      t.references :calendar_integration, null: false, foreign_key: true, type: :uuid
      t.string :external_event_id, null: false
      t.string :external_booking_uid
      t.datetime :last_synced_at

      # --- System Fields ---
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :calendar_sync_mappings,
      [ :external_event_id, :calendar_integration_id ],
      unique: true,
      name: "idx_sync_mappings_ext_id"
  end
end
