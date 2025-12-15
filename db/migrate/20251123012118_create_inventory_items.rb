class CreateInventoryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_items, id: :uuid do |t|
      t.references :inventory, null: false, foreign_key: true, type: :uuid

      t.integer :education_type
      t.integer :hospital_type
      t.integer :hotel_type
      t.integer :restaurant_type
      t.integer :retail_type

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
      t.datetime :expiration_date
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :inventory_items, :sku
    add_index :inventory_items, :barcode
    add_index :inventory_items, :upc
    add_index :inventory_items, :ean
    add_index :inventory_items, :serial_number
    add_index :inventory_items, :discarded_at
  end
end
