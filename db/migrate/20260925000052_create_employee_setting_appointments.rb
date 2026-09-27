class CreateEmployeeSettingAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_setting_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: { to_table: :employees }, type: :uuid
      t.references :setting, null: false, foreign_key: { to_table: :settings }, type: :uuid
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
    add_index :employee_setting_appointments, [:company_id, :employee_id, :setting_id], unique: true, name: "idx_employee_setting_appointments_uniq"
  end
end
