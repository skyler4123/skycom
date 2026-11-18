class CreatePickTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :pick_tasks, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :pick_wave, null: false, foreign_key: true, type: :uuid
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
      t.references :stock_lot, foreign_key: true, type: :uuid
      t.references :storage_location, foreign_key: true, type: :uuid
      t.references :assigned_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Work ---
      t.integer  :quantity, null: false, default: 0
      t.integer  :picked_quantity, null: false, default: 0
      t.integer  :status, null: false, default: 0
      t.datetime :completed_at
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

    add_index :pick_tasks, [ :pick_wave_id, :status ]
    add_index :pick_tasks, [ :assigned_employee_id, :status ]
  end
end
