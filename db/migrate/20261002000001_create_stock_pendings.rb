class CreateStockPendings < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_pendings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.text :reason
      t.string :code, index: { unique: true }
      t.integer :quantity, null: false
      t.datetime :status_changed_at
      t.datetime :released_at

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
    add_index :stock_pendings, %i[company_id workflow_status]
    add_index :stock_pendings, %i[stock_id workflow_status]
    add_index :stock_pendings, %i[warehouse_id workflow_status]
  end
end
