# frozen_string_literal: true

class CreateOperationWarehouseAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :operation_warehouse_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :operation, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.string :external_id

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :operation_warehouse_appointments, [ :company_id, :operation_id, :warehouse_id ], unique: true,
      name: "idx_operation_warehouse_appointments_uniq"
  end
end
