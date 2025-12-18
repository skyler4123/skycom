class CreateBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :brands, id: :uuid do |t|
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :brands, :discarded_at
  end
end
