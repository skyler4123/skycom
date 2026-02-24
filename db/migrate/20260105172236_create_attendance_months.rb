class CreateAttendanceMonths < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_months, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :logable, polymorphic: true, null: false, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
