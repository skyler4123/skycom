class CreateCalendarEquipments < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_equipments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      # Polymorphic bridge into core ERP models (Stock / Product), or nil for a
      # calendar-only device. See Calendar::SourceLinkConcern::SOURCE_TYPES.
      t.string   :source_type
      t.uuid     :source_id

      t.string   :name, null: false
      t.string   :code
      t.text     :description
      t.integer  :quantity, null: false, default: 1
      t.string   :color, null: false, default: "#f59e0b"
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

    add_index :calendar_equipments, [ :company_id, :name ], unique: true
    add_index :calendar_equipments, [ :source_type, :source_id ]
    add_index :calendar_equipments, [ :external_provider, :external_id ]
  end
end
