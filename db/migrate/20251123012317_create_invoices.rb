class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :currency
      t.integer :duration
      t.string :number
      t.decimal :total_price
      t.datetime :due_date
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :invoices, :discarded_at
  end
end
