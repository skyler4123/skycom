class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
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
      t.integer :currency
      t.integer :duration
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :orders, :sku
    add_index :orders, :barcode
    add_index :orders, :upc
    add_index :orders, :ean
    add_index :orders, :serial_number
    add_index :orders, :discarded_at
  end
end
