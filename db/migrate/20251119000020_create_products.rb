class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :company, null: false, foreign_key: true
      t.references :product_brand, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :products, :discarded_at
  end
end
