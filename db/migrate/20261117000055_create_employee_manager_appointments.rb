class CreateEmployeeManagerAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_manager_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :manager_employee, null: false, foreign_key: { to_table: :employees }, type: :uuid

      # --- Line ---
      t.integer :relationship_type, null: false, default: 0
      t.date    :effective_from
      t.date    :effective_to

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

    add_index :employee_manager_appointments, [ :employee_id, :manager_employee_id, :relationship_type ], unique: true, name: "idx_employee_manager_unique"
  end
end
