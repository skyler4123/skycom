class CreateDiscounts < ActiveRecord::Migration[8.0]
  def change
    create_table :discounts, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :discount_group, null: false, foreign_key: true, type: :uuid
      # SoT references — populated by the reserve/consume transitions.
      t.references :order, foreign_key: true, type: :uuid
      t.references :invoice, foreign_key: true, type: :uuid
      t.references :customer, foreign_key: true, type: :uuid
      t.references :employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Identity ---
      t.string :code, null: false

      # --- Consumption state ---
      t.integer  :status, default: 0, null: false
      t.integer  :amount_cents
      t.datetime :used_at

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

    add_index :discounts, [ :company_id, :code ], unique: true
    add_index :discounts, [ :discount_group_id, :status ]
    add_index :discounts, :status
  end
end
