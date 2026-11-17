class CreatePurchaseParentAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_parent_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :purchase, null: false, foreign_key: true, type: :uuid
      t.references :related_purchase, null: false, foreign_key: { to_table: :purchases }, type: :uuid

      # --- Link ---
      t.integer :link_type, null: false, default: 0

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

    add_index :purchase_parent_appointments, [ :purchase_id, :related_purchase_id, :link_type ], unique: true, name: "idx_purchase_parent_unique"
  end
end
