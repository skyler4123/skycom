class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.integer :currency
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
