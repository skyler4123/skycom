# frozen_string_literal: true

# Creates the per-record audit log for an Import. Every successfully created
# row writes one log pointing at the new record; RollbackService replays the
# logs (newest first) to destroy only the records this import created.
class CreateImportLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :import_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :import, null: false, foreign_key: true, type: :uuid, index: false
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :record_type, null: false
      t.uuid :record_id, null: false
      t.integer :action, null: false
      t.integer :source_row
      t.jsonb :previous_state, null: false, default: {}
      t.string :resource

      # --- System Fields (no lifecycle_status: workflow_status only) ---
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :import_logs, [ :import_id, :record_type, :record_id ],
              unique: true, name: "idx_import_logs_unique_record"
    add_index :import_logs, [ :record_type, :record_id ]
  end
end
