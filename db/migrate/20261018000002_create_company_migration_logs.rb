class CreateCompanyMigrationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :company_migration_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company_migration, null: false, foreign_key: true, type: :uuid, index: false
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :record_type
      t.uuid :record_id
      t.integer :action
      t.jsonb :previous_state, default: {}
      t.string :resource
      t.integer :source_row

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_migration_logs, [ :company_migration_id, :record_type, :record_id ],
              unique: true, name: "idx_company_migration_logs_unique_record"
    add_index :company_migration_logs, [ :record_type, :record_id ]
  end
end
