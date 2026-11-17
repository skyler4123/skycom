class CreateCourseLessons < ActiveRecord::Migration[8.0]
  def change
    create_table :course_lessons, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :course, null: false, foreign_key: true, type: :uuid

      # --- Lesson ---
      t.integer :position, null: false, default: 1
      t.string  :title, null: false
      t.text    :body_markdown
      t.integer :duration_minutes

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

    add_index :course_lessons, [ :course_id, :position ], unique: true
  end
end
