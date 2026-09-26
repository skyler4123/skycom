class CreateStockItemAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_item_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid

      t.integer :quantity, null: false

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

    add_index :stock_item_appointments, [ :appoint_to_type, :appoint_to_id, :stock_id ],
      name: "idx_stock_items_on_appoint_to_and_stock"
  end
end
