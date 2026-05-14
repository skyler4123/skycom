class CreateAddressAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :address_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :address, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.string :value

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
    add_index :address_appointments, [ :appoint_to_type, :appoint_to_id ]
  end
end
