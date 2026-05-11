class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :cart_group, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.string :sku
      t.string :barcode
      t.string :upc
      t.string :ean
      t.string :manufacturer_code
      t.string :serial_number
      t.string :batch_number

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(20) { |i| t.string "dynamic_property_string_#{i}" }
      1.upto(20) { |i| t.integer "dynamic_property_integer_#{i}" }
      1.upto(10)  { |i| t.decimal "dynamic_property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(10)  { |i| t.boolean "dynamic_property_boolean_#{i}" }
      1.upto(10)  { |i| t.boolean "dynamic_property_datetime_#{i}" }

      t.timestamps
    end
    add_index :carts, :sku
    add_index :carts, :barcode
    add_index :carts, :upc
    add_index :carts, :ean
    add_index :carts, :serial_number
  end
end
