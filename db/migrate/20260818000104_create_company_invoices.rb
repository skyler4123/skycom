# frozen_string_literal: true

class CreateCompanyInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :company_invoices, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :company_order, null: true, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :invoice_number, null: false
      t.bigint :money_amount_cents, null: false
      t.bigint :credit_amount, null: false
      t.integer :currency, null: false
      t.integer :payment_status, null: false, default: 0

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_invoices, :invoice_number, unique: true
    add_index :company_invoices, [ :company_id, :created_at ]
  end
end
