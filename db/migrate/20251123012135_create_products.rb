class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid
      t.references :brand, null: true, foreign_key: true, type: :uuid
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
    add_index :products, :sku
    add_index :products, :barcode
    add_index :products, :upc
    add_index :products, :ean
    add_index :products, :serial_number
    add_index :products, :discarded_at
  end
end
