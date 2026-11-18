class CreatePurchaseMatchAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_match_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :purchase, null: false, foreign_key: true, type: :uuid
      t.references :related_purchase, foreign_key: { to_table: :purchases }, type: :uuid
      t.references :stock_import, foreign_key: true, type: :uuid

      # --- Match ---
      t.integer :matched_quantity, null: false, default: 0
      t.bigint  :matched_amount_cents, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text    :notes

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

    add_index :purchase_match_appointments, [ :company_id, :status ]
  end
end
