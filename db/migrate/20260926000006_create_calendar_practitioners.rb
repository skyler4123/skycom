class CreateCalendarPractitioners < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_practitioners, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_position, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      # Polymorphic bridge into core ERP models. The calendar module never
      # references Employee / User directly — only through this pair.
      # See Calendar::SourceLinkConcern::SOURCE_TYPES.
      t.string   :source_type, null: false
      t.uuid     :source_id, null: false

      t.string   :name, null: false
      t.string   :color
      t.boolean  :bookable, null: false, default: true

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

    add_index :calendar_practitioners, [ :company_id, :source_type, :source_id ], unique: true,
      name: "idx_calendar_practitioners_source"
    add_index :calendar_practitioners, [ :calendar_position_id, :company_id ]
    add_index :calendar_practitioners, [ :external_provider, :external_id ]
  end
end
