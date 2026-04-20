class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :invoice, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :currency_code
      t.integer :duration
      t.decimal :exchange_rate
      t.decimal :amount
      t.string :payment_method
      t.string :gateway_details
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :payments, :discarded_at
  end
end
