# frozen_string_literal: true

# CreateExamFeatureTables — clean schema for the question bank and exams.
class CreateExamFeatureTables < ActiveRecord::Migration[8.1]
  def change
    create_table :questions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.text :description
      t.integer :question_type, null: false, default: 0
      t.integer :points, null: false, default: 1
      t.text :correct_text

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :questions, [ :company_id, :category_id ]
    add_index :questions, [ :company_id, :question_type ]
    add_index :questions, [ :company_id, :name ]

    create_table :question_options, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :question, null: false, foreign_key: true, type: :uuid

      t.string :content, null: false
      t.boolean :correct, null: false, default: false
      t.integer :position, null: false, default: 0

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :question_options, [ :question_id, :position ]

    create_table :exams, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.text :description
      t.integer :duration_minutes
      t.decimal :passing_score, precision: 5, scale: 2, null: false, default: 70.0
      t.integer :max_attempts, default: 1
      t.boolean :shuffle_options, null: false, default: true

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status, null: false, default: 0
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.datetime :published_at

      t.timestamps
    end

    add_index :exams, [ :company_id, :name ], unique: true
    add_index :exams, [ :company_id, :workflow_status ]

    create_table :exam_question_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :exam, null: false, foreign_key: true, type: :uuid
      t.references :question, null: false, foreign_key: true, type: :uuid

      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :exam_question_appointments, [ :exam_id, :question_id ], unique: true
    add_index :exam_question_appointments, [ :exam_id, :position ]

    create_table :employee_exam_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: { to_table: :employees }, type: :uuid
      t.references :exam, null: false, foreign_key: true, type: :uuid

      t.uuid :assigned_by_employee_id
      t.uuid :graded_by_employee_id
      t.integer :attempt_number, null: false, default: 1
      t.datetime :started_at
      t.datetime :deadline_at
      t.datetime :submitted_at
      t.datetime :graded_at
      t.integer :question_count, null: false, default: 0
      t.integer :correct_count, null: false, default: 0
      t.decimal :total_points, precision: 8, scale: 2, null: false, default: 0
      t.decimal :earned_points, precision: 8, scale: 2, null: false, default: 0
      t.decimal :score, precision: 5, scale: 2
      t.boolean :passed

      t.string :name
      t.string :description
      t.string :code

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status, null: false, default: 0
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :employee_exam_appointments,
      [ :company_id, :employee_id, :exam_id, :attempt_number ],
      unique: true,
      name: "idx_employee_exam_attempt_uniq"
    add_index :employee_exam_appointments,
      [ :company_id, :employee_id, :exam_id ],
      unique: true,
      where: "workflow_status IN (0, 1)",
      name: "idx_employee_exam_active_uniq"
    add_index :employee_exam_appointments, [ :exam_id, :workflow_status ]
    add_index :employee_exam_appointments, [ :employee_id, :workflow_status ]
    add_foreign_key :employee_exam_appointments, :employees, column: :assigned_by_employee_id, on_delete: :nullify
    add_foreign_key :employee_exam_appointments, :employees, column: :graded_by_employee_id, on_delete: :nullify

    create_table :employee_question_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee_exam_appointment, null: false, foreign_key: true, type: :uuid
      t.references :question, null: false, foreign_key: true, type: :uuid

      t.integer :question_type, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.jsonb :question_snapshot, null: false, default: {}
      t.jsonb :option_order, null: false, default: []
      t.jsonb :selected_option_ids, null: false, default: []
      t.text :text_answer
      t.boolean :correct
      t.decimal :points_possible, precision: 8, scale: 2, null: false, default: 0
      t.decimal :points_awarded, precision: 8, scale: 2, null: false, default: 0
      t.datetime :graded_at
      t.uuid :graded_by_employee_id

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :employee_question_appointments,
      [ :employee_exam_appointment_id, :question_id ],
      unique: true,
      name: "idx_employee_question_attempt_uniq"
    add_foreign_key :employee_question_appointments, :employees, column: :graded_by_employee_id, on_delete: :nullify

    create_table :exam_summaries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :exam, null: false, foreign_key: true, type: :uuid, index: { unique: true }

      t.integer :assigned_count, null: false, default: 0
      t.integer :started_count, null: false, default: 0
      t.integer :submitted_count, null: false, default: 0
      t.integer :graded_count, null: false, default: 0
      t.integer :passed_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.integer :pending_review_count, null: false, default: 0
      t.integer :expired_count, null: false, default: 0
      t.decimal :average_score, precision: 5, scale: 2
      t.decimal :highest_score, precision: 5, scale: 2
      t.decimal :lowest_score, precision: 5, scale: 2
      t.decimal :pass_rate, precision: 5, scale: 2
      t.jsonb :question_stats, null: false, default: {}
      t.datetime :computed_at

      t.timestamps
    end
  end
end
