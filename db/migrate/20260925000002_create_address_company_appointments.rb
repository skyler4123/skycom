class CreateAddressCompanyAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :address_company_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :address, null: false, foreign_key: { to_table: :addresses }, type: :uuid
      t.references :company, null: false, foreign_key: { to_table: :companies }, type: :uuid
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
    add_index :address_company_appointments, [:address_id, :company_id], unique: true, name: "idx_address_company_appointments_uniq"
  end
end
