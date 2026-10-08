class CreateEmployeeNotificationReads < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_notification_reads, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :notification, null: false, foreign_key: true, type: :uuid
      t.datetime :read_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

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

    add_index :employee_notification_reads, [ :employee_id, :notification_id ], unique: true,
      name: "idx_emp_notif_reads_on_emp_notif"
    add_index :employee_notification_reads, [ :company_id, :employee_id ],
      name: "idx_emp_notif_reads_on_company_emp"
  end
end
