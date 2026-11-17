class CreateDataExports < ActiveRecord::Migration[8.0]
  def change
    create_table :data_exports, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :requested_by_employee, foreign_key: { to_table: :employees }, type: :uuid
      t.references :stored_file, foreign_key: true, type: :uuid

      # --- Export ---
      t.string   :export_type, null: false, default: "full"
      t.integer  :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.text     :error_message

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

    add_index :data_exports, [ :company_id, :status ]
  end
end
