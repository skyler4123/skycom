class CreateStoredFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :stored_files, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :folder, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.bigint :file_size, default: 0
      t.string :extension
      t.string :content_type

      # Polymorphic owner for business reuse (Invoice PDF, Purchase bill image, ...).
      t.string :attachable_type
      t.uuid :attachable_id

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

    add_index :stored_files, [ :company_id, :folder_id ]
    add_index :stored_files, [ :attachable_type, :attachable_id ]
  end
end
