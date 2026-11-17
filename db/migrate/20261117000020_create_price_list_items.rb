class CreatePriceListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :price_list_items, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :price_list, null: false, foreign_key: true, type: :uuid
      t.references :product, foreign_key: true, type: :uuid
      t.references :service, foreign_key: true, type: :uuid

      # --- Price ---
      t.integer :min_quantity, null: false, default: 1
      t.bigint  :price_cents, null: false, default: 0
      t.integer :currency, default: 840

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

    add_index :price_list_items, [ :price_list_id, :product_id, :min_quantity ], unique: true, name: "idx_price_list_items_product"
    add_index :price_list_items, [ :price_list_id, :service_id, :min_quantity ], unique: true, name: "idx_price_list_items_service"
  end
end
