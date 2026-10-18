class CreateCompanyMigrations < ActiveRecord::Migration[8.0]
  def change
    create_table :company_migrations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :folder, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.string :target_resource
      t.string :source_filename
      t.bigint :source_file_size

      t.jsonb :migration_mapping_config, default: {}
      t.jsonb :dry_run_result

      t.integer :total_chunks, default: 0
      t.bigint :total_rows, default: 0
      t.bigint :processed_rows, default: 0
      t.bigint :created_rows, default: 0
      t.bigint :updated_rows, default: 0
      t.bigint :failed_rows, default: 0

      t.datetime :approved_at
      t.datetime :completed_at
      t.datetime :rolled_back_at

      t.string :external_id, index: true

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
  end
end
