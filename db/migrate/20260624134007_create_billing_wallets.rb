class CreateBillingWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_wallets, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.text   :description
      t.integer :country
      t.integer :currency, null: false

      # --- Billing Fields ---
      t.integer  :promo_balance_cents, null: false
      t.integer  :main_balance_cents, null: false
      t.integer  :soft_debt_threshold_cents, null: false
      t.datetime :suspension_at
      t.boolean  :hide_billing_alerts, null: false
      t.datetime :has_unpaid_invoices_at

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
