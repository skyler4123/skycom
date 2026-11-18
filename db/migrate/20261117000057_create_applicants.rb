class CreateApplicants < ActiveRecord::Migration[8.0]
  def change
    create_table :applicants, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :job_opening, null: false, foreign_key: true, type: :uuid
      t.references :resume_stored_file, foreign_key: { to_table: :stored_files }, type: :uuid
      t.references :workflow_step, foreign_key: true, type: :uuid

      # --- Candidate ---
      t.string  :name, null: false
      t.string  :email
      t.string  :phone_number
      t.string  :source
      t.integer :stage, null: false, default: 0
      t.text    :notes

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

    add_index :applicants, [ :company_id, :stage ]
    add_index :applicants, [ :job_opening_id, :stage ]
  end
end
