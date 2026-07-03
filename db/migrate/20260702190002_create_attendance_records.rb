class CreateAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_records, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :scheduled_shift, null: true, foreign_key: true, type: :uuid
      t.datetime :check_in_at, null: false
      t.datetime :check_out_at
      t.datetime :break_start
      t.datetime :break_end
      t.integer :total_work_minutes, default: 0
      t.integer :late_minutes, default: 0
      t.integer :early_leave_minutes, default: 0
      t.integer :overtime_minutes, default: 0
      t.string :computed_status, default: "pending", null: false

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
  end
end
