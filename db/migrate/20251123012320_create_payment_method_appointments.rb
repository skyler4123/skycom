class CreatePaymentMethodAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_method_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :payment_method, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code

      # --- Merchant Bank Account Credentials ---
      t.string :merchant_number           # Merchant's bank account number
      t.string :merchant_name             # Merchant's bank account holder name
      t.string :merchant_id              # Terminal / Merchant ID given by gateway

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
    add_index :payment_method_appointments, [ :payment_method_id, :company_id ]
  end
end
