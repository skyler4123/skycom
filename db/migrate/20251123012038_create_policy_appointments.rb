class CreatePolicyAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_appointments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :policy, null: false, foreign_key: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid

      t.string :name
      t.string :description
      t.string :code

      # --- System Fields ---
      t.integer  :lifecycle_status
      t.integer  :workflow_status
      t.integer  :business_type
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
    add_index :policy_appointments, [ :appoint_to_type, :appoint_to_id ]
  end
end
