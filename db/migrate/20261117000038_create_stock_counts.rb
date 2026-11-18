class CreateStockCounts < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_counts, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :created_by_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Count ---
      t.integer  :count_type, null: false, default: 1
      t.date     :scheduled_on
      t.datetime :started_at
      t.datetime :completed_at
      t.integer  :status, null: false, default: 0
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

    add_index :stock_counts, [ :company_id, :scheduled_on ]
    add_index :stock_counts, [ :warehouse_id, :status ]
  end
end
