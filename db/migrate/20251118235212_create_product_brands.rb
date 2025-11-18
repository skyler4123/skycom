class CreateProductBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :product_brands do |t|
      t.string :name
      t.string :description
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :product_brands, :discarded_at
  end
end
