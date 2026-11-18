class CreateCustomerUserAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_user_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      # --- Access ---
      t.integer  :role, null: false, default: 0
      t.datetime :invited_at
      t.datetime :accepted_at
      t.datetime :revoked_at

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :customer_user_appointments, [ :customer_id, :user_id ], unique: true
  end
end
