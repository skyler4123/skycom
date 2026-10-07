class CreateNotificationTagAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_tag_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :notification, null: false, foreign_key: true, type: :uuid
      t.references :notification_tag, null: false, foreign_key: true, type: :uuid

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :notification_tag_appointments,
      [ :company_id, :notification_id, :notification_tag_id ],
      unique: true,
      name: "idx_notif_tag_appt_on_company_notif_tag"
  end
end
