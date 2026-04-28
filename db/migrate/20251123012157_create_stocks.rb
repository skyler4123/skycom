class CreateStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :stocks, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.integer :quantity
      t.string :code
      t.string :sku
      t.string :barcode
      t.string :upc
      t.string :ean
      t.string :manufacturer_code
      t.string :serial_number
      t.string :batch_number
      t.datetime :expiration_date
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :stocks, :sku
    add_index :stocks, :barcode
    add_index :stocks, :upc
    add_index :stocks, :ean
    add_index :stocks, :serial_number
    add_index :stocks, :discarded_at
  end
end
