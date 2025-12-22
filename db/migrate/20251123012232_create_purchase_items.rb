class CreatePurchaseItems < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_items, id: :uuid do |t|
      t.references :purchase, null: false, foreign_key: true, type: :uuid
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
      t.datetime :expiration_date
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :purchase_items, :sku
    add_index :purchase_items, :barcode
    add_index :purchase_items, :upc
    add_index :purchase_items, :ean
    add_index :purchase_items, :serial_number
    add_index :purchase_items, :discarded_at
  end
end
