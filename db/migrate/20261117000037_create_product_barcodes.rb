class CreateProductBarcodes < ActiveRecord::Migration[8.0]
  def change
    create_table :product_barcodes, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      # --- Code ---
      t.string  :barcode, null: false
      t.integer :pack_quantity, null: false, default: 1
      t.boolean :is_primary, null: false, default: false

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

    add_index :product_barcodes, [ :company_id, :barcode ], unique: true
    add_index :product_barcodes, [ :product_id, :is_primary ]
  end
end
