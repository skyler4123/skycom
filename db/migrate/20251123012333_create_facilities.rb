class CreateFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :facilities, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid

      t.integer :education_type
      t.integer :hospital_type
      t.integer :hotel_type
      t.integer :restaurant_type
      t.integer :retail_type

      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :facilities, :discarded_at
  end
end
