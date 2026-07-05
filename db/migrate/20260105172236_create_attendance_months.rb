class CreateAttendanceMonths < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_months, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.date :month, null: false
      t.integer :total_work_minutes, default: 0
      t.integer :total_late_minutes, default: 0
      t.integer :total_early_leave_minutes, default: 0
      t.integer :total_overtime_minutes, default: 0
      t.integer :total_absent_days, default: 0
      t.integer :total_present_days, default: 0
      t.integer :total_records, default: 0
      t.integer :total_deficit_minutes, default: 0

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :attendance_months, [ :employee_id, :month ], unique: true
  end
end
