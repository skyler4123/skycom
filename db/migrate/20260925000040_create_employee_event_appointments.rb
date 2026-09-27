class CreateEmployeeEventAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_event_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: { to_table: :employees }, type: :uuid
      t.references :event, null: false, foreign_key: { to_table: :events }, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :employee_event_appointments, [:company_id, :employee_id, :event_id], unique: true, name: "idx_employee_event_appointments_uniq"
  end
end
