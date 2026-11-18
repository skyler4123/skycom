class CreateJobOpenings < ActiveRecord::Migration[8.0]
  def change
    create_table :job_openings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :department, foreign_key: true, type: :uuid

      # --- Opening ---
      t.string  :title, null: false
      t.text    :description
      t.integer :openings_count, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.date    :opened_on
      t.date    :closed_on

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

    add_index :job_openings, [ :company_id, :status ]

    add_foreign_key :employees, :job_openings, column: :job_opening_id
  end
end
