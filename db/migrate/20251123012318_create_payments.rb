class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :invoice, null: false, foreign_key: true, type: :uuid
      t.integer :education_type
      t.integer :hospital_type
      t.integer :hotel_type
      t.integer :restaurant_type
      t.integer :retail_type
      t.string :name
      t.string :description
      t.string :code
      t.integer :currency
      t.integer :duration
      t.decimal :exchange_rate
      t.decimal :amount
      t.string :payment_method
      t.string :gateway_details
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :payments, :discarded_at
  end
end
