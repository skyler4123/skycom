class CreateSubcontractOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :subcontract_orders, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :supplier, null: false, foreign_key: true, type: :uuid
      t.references :purchase, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      # --- Job ---
      t.string   :code
      t.decimal  :quantity, precision: 15, scale: 4, null: false, default: 0.0
      t.decimal  :sent_quantity, precision: 15, scale: 4, null: false, default: 0.0
      t.decimal  :received_quantity, precision: 15, scale: 4, null: false, default: 0.0
      t.integer  :status, null: false, default: 0
      t.date     :sent_on
      t.date     :due_on
      t.text     :notes

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

    add_index :subcontract_orders, [ :company_id, :status ]
    add_index :subcontract_orders, [ :supplier_id, :due_on ]
  end
end
