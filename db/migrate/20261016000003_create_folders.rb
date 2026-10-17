class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.uuid :parent_id
      t.string :name, null: false

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

    add_index :folders, [ :company_id, :parent_id ]
    add_index :folders, [ :company_id, :parent_id, :name ], unique: true, name: "idx_folders_parent_name_uniq"
    add_index :folders, :parent_id
  end
end
