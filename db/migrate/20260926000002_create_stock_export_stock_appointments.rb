class CreateStockExportStockAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_export_stock_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :stock_export, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
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

    add_index :stock_export_stock_appointments, [ :company_id, :stock_export_id, :stock_id ],
      name: "idx_export_stock_triple"
  end
end
