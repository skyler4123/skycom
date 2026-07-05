class CreateScheduledShifts < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduled_shifts, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :shift_template, null: true, foreign_key: true, type: :uuid
      t.date :work_date, null: false
      t.datetime :expected_start_at, null: false
      t.datetime :expected_end_at, null: false
      t.string :status, null: false

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :scheduled_shifts, [ :employee_id, :work_date ], unique: true
  end
end
