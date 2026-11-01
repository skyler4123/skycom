# frozen_string_literal: true

# Creates the Import run tracker. Each row is one user-prepared CSV import:
# target table + one category, the uploaded source file, dry-run result,
# counters, and the approve → run / rollback lifecycle. See docs/IMPORT.md.
class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :folder, null: false, foreign_key: true, type: :uuid
      t.references :creator, null: false, foreign_key: { to_table: :employees }, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.text :description
      t.string :target_table
      t.string :target_model

      t.jsonb :schema_snapshot, null: false, default: {}
      t.jsonb :dry_run_result
      t.jsonb :error_samples, null: false, default: []

      t.string :source_filename
      t.bigint :source_file_size
      t.string :source_digest

      t.bigint :total_rows, null: false, default: 0
      t.bigint :processed_rows, null: false, default: 0
      t.bigint :created_rows, null: false, default: 0
      t.bigint :failed_rows, null: false, default: 0

      t.datetime :approved_at
      t.datetime :completed_at
      t.datetime :rolled_back_at

      # --- System Fields (workflow_status is the import lifecycle, see IMPORT_WORKFLOW_STATUS) ---
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :imports, :workflow_status
    add_index :imports, :target_table
  end
end
