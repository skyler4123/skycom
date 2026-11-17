class CreateApplicantInterviews < ActiveRecord::Migration[8.0]
  def change
    create_table :applicant_interviews, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :applicant, null: false, foreign_key: true, type: :uuid
      t.references :employee, foreign_key: true, type: :uuid

      # --- Interview ---
      t.datetime :scheduled_at, null: false
      t.datetime :completed_at
      t.integer  :outcome, null: false, default: 0
      t.text     :notes

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

    add_index :applicant_interviews, [ :applicant_id, :scheduled_at ]
  end
end
