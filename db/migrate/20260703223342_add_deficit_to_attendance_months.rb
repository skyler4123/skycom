class AddDeficitToAttendanceMonths < ActiveRecord::Migration[8.0]
  def change
    add_column :attendance_months, :total_deficit_minutes, :integer
  end
end
