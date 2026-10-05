class CreateCustomerServiceAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_service_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: { to_table: :customers }, type: :uuid
      t.references :service, null: false, foreign_key: { to_table: :services }, type: :uuid
      t.integer :duration
      t.datetime :start_at
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
    add_index :customer_service_appointments, [ :company_id, :customer_id, :service_id ], unique: true, name: "idx_customer_service_appointments_uniq"
  end
end
