class CreatePolicyRoleAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_role_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :policy, null: false, foreign_key: { to_table: :policies }, type: :uuid
      t.references :role, null: false, foreign_key: { to_table: :roles }, type: :uuid
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
    add_index :policy_role_appointments, [:company_id, :policy_id, :role_id], unique: true, name: "idx_policy_role_appointments_uniq"
  end
end
