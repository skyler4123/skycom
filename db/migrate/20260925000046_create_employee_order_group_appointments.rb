class CreateEmployeeOrderGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_order_group_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: { to_table: :employees }, type: :uuid
      t.references :order_group, null: false, foreign_key: { to_table: :order_groups }, type: :uuid
      t.decimal :unit_price
      t.integer :quantity
      t.decimal :total_price
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
    add_index :employee_order_group_appointments, [:company_id, :employee_id, :order_group_id], name: "idx_employee_order_group_appointments_triple"
  end
end
