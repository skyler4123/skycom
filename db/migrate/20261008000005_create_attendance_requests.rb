class CreateAttendanceRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_requests, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.date :attendance_date, null: false
      t.datetime :check_in, null: false
      t.datetime :check_out
      t.text :reason, null: false
      t.integer :status, null: false, default: 0
      t.references :decided_by, null: true, foreign_key: { to_table: :employees }, type: :uuid
      t.datetime :decided_at
      t.text :decision_note

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :attendance_requests,
      [ :company_id, :employee_id, :attendance_date ],
      unique: true,
      where: "discarded_at IS NULL",
      name: "idx_attendance_requests_on_company_employee_date"
    add_index :attendance_requests, :status
  end
end
