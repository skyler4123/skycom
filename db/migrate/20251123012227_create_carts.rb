class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid
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
      t.datetime :expiration_date
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :carts, :sku
    add_index :carts, :barcode
    add_index :carts, :upc
    add_index :carts, :ean
    add_index :carts, :serial_number
    add_index :carts, :discarded_at
  end
end
