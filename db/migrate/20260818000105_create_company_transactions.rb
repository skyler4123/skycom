# frozen_string_literal: true

class CreateCompanyTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :company_transactions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :company_invoice, null: false, foreign_key: true, type: :uuid
      t.references :company_payment_method, null: false, foreign_key: true, type: :uuid
      t.integer :transaction_type, null: false
      t.bigint :money_amount_cents, null: false
      t.integer :currency, null: false
      t.integer :status, null: false, default: 0
      t.string :gateway_reference

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_transactions, :gateway_reference, unique: true
    add_index :company_transactions, [ :company_id, :created_at ]
  end
end
