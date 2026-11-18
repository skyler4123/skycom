class CreateExchangeRates < ActiveRecord::Migration[8.0]
  def change
    create_table :exchange_rates, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, foreign_key: true, type: :uuid

      # --- Pair ---
      t.integer :base_currency,  null: false
      t.integer :quote_currency, null: false
      t.decimal :rate, precision: 18, scale: 10, null: false
      t.date    :effective_on, null: false
      t.string  :source

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :exchange_rates, [ :company_id, :base_currency, :quote_currency, :effective_on ], unique: true, name: "idx_exchange_rates_pair"
    add_index :exchange_rates, [ :base_currency, :quote_currency, :effective_on ]
  end
end
