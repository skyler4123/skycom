class CreateTableConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :table_configs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      # Optional: if layouts change per category
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :resource_name

      t.jsonb :fields, null: false, default: []

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
    add_index :table_configs, [ :company_id, :resource_name, :category_id ]
  end
end
