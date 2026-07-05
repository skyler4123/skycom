class CreateAttendanceDays < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_days, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.date :attendance_date, null: false
      t.datetime :check_in
      t.datetime :check_out
      t.datetime :break_start
      t.datetime :break_end
      t.integer :total_seconds_present, default: 0
      t.integer :total_seconds_break, default: 0
      t.integer :total_seconds_worked, default: 0
      t.integer :total_seconds_overtime, default: 0
      t.integer :attendance_status
      t.integer :recorded_method
      t.text :notes
      t.string :approved_by_type
      t.uuid :approved_by_id
      t.datetime :approved_at
      t.string :edited_by_type
      t.uuid :edited_by_id
      t.datetime :edited_at

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
