class CreateCalendarAvailabilityRules < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_availability_rules, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_practitioner, null: true, foreign_key: true, type: :uuid
      t.references :calendar_location, null: true, foreign_key: true, type: :uuid

      t.string   :name
      t.string   :timezone, null: false, default: "UTC"

      # ISO weekday numbers (1 = Monday ... 7 = Sunday). Empty means every day.
      t.integer  :days_of_week, array: true, null: false, default: []

      # "HH:MM" 24h wall-clock in `timezone`. No overnight spans in v1.
      t.string   :start_time, null: false
      t.string   :end_time, null: false

      t.date     :effective_from
      t.date     :effective_to
      t.integer  :priority, null: false, default: 0

      # Set true for blackout / leave blocks that subtract from availability.
      t.boolean  :is_unavailable, null: false, default: false

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

    # Exactly one owner: a rule belongs to a practitioner OR a location.
    add_check_constraint :calendar_availability_rules,
      "num_nonnulls(calendar_practitioner_id, calendar_location_id) = 1",
      name: "chk_calendar_availability_rules_single_owner"
    add_check_constraint :calendar_availability_rules,
      "end_time > start_time",
      name: "chk_calendar_availability_rules_time_order"

    add_index :calendar_availability_rules, [ :company_id, :calendar_practitioner_id ],
      name: "idx_calendar_availability_rules_practitioner"
    add_index :calendar_availability_rules, [ :company_id, :calendar_location_id ],
      name: "idx_calendar_availability_rules_location"
  end
end
