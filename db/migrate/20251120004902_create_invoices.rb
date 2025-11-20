class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :order, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.string :currency
      t.string :number
      t.string :total
      t.datetime :due_date
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :invoices, :discarded_at
  end
end
