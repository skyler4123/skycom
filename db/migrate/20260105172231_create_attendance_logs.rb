class CreateAttendanceLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_logs, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :logable, polymorphic: true, null: false, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.string :location
      t.string :id_address
      t.string :device_info
      t.text :notes

      t.timestamps
    end
  end
end
