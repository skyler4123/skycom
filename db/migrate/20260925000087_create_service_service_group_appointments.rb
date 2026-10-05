class CreateServiceServiceGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :service_service_group_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :service, null: false, foreign_key: { to_table: :services }, type: :uuid
      t.references :service_group, null: false, foreign_key: { to_table: :service_groups }, type: :uuid
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
    add_index :service_service_group_appointments, [ :company_id, :service_id, :service_group_id ], unique: true, name: "idx_service_service_group_appointments_uniq"
  end
end
