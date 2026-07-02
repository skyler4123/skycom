class UpdateShiftsReplacePeriodWithTimeColumns < ActiveRecord::Migration[8.0]
  def change
    remove_reference :shifts, :period, foreign_key: true, type: :uuid
    add_column :shifts, :start_time, :time, null: false
    add_column :shifts, :end_time, :time, null: false
  end
end
