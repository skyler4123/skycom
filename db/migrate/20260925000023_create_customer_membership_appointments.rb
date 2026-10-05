class CreateCustomerMembershipAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_membership_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: { to_table: :customers }, type: :uuid
      t.references :membership, null: false, foreign_key: { to_table: :memberships }, type: :uuid
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
    add_index :customer_membership_appointments, [ :company_id, :customer_id, :membership_id ], unique: true, name: "idx_customer_membership_appointments_uniq"
  end
end
