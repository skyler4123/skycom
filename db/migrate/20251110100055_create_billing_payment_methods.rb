class CreateBillingPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_payment_methods, id: :uuid, default: -> { "uuidv7()" } do |t|
      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency
      t.integer :country
      t.integer :timezone
      t.integer :payment_mode, index: true
      t.string :gateway_url
      t.string :secret_key

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
  end
end
