class CreateAddressCustomerGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :address_customer_group_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: true, foreign_key: true, type: :uuid
      t.references :address, null: false, foreign_key: { to_table: :addresses }, type: :uuid
      t.references :customer_group, null: false, foreign_key: { to_table: :customer_groups }, type: :uuid
      t.string :value
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
    add_index :address_customer_group_appointments, [:company_id, :address_id, :customer_group_id], unique: true, name: "idx_address_customer_group_appointments_uniq"
  end
end
