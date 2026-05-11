class CreateFacilityAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :facility_appointments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :facility, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code

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
    add_index :facility_appointments, [ :appoint_to_type, :appoint_to_id ]
  end
end
