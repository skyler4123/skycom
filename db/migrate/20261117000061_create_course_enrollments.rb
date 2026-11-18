class CreateCourseEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :course_enrollments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :course, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :exam, foreign_key: true, type: :uuid

      # --- Enrollment ---
      t.integer :status, null: false, default: 0
      t.integer :progress_percent, null: false, default: 0
      t.date    :started_on
      t.date    :completed_on
      t.date    :expires_on

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :course_enrollments, [ :course_id, :employee_id ], unique: true
    add_index :course_enrollments, [ :company_id, :expires_on ]
  end
end
