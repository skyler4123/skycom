class CreateAttendanceDays < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_days, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :logable, polymorphic: true, null: false, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.date :attendance_date
      t.datetime :check_in
      t.datetime :check_out
      t.datetime :break_start
      t.datetime :break_end
      t.integer :total_seconds_present
      t.integer :total_seconds_break
      t.integer :total_seconds_worked
      t.integer :total_seconds_overtime
      t.integer :shift_id
      t.integer :attendance_status
      t.integer :recorded_method
      t.string :ip_address
      t.string :device_id
      t.decimal :location_lat
      t.decimal :location_lng
      t.text :notes
      t.references :approved_by, polymorphic: true, null: false, type: :uuid
      t.datetime :approved_at
      t.references :edited_by, polymorphic: true, null: false, type: :uuid
      t.datetime :edited_at

      t.timestamps
    end
  end
end
