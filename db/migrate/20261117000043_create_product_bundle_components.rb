class CreateProductBundleComponents < ActiveRecord::Migration[8.0]
  def change
    create_table :product_bundle_components, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :product_bundle, null: false, foreign_key: true, type: :uuid
      t.references :component_product, null: false, foreign_key: { to_table: :products }, type: :uuid

      # --- Component ---
      t.integer :quantity, null: false, default: 1
      t.boolean :is_optional, null: false, default: false

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

    add_index :product_bundle_components, [ :product_bundle_id, :component_product_id ], unique: true, name: "idx_bundle_components_unique"
  end
end
