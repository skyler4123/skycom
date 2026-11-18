class CreateDataSubjectRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :data_subject_requests, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, foreign_key: true, type: :uuid
      t.references :employee, foreign_key: true, type: :uuid
      t.references :user, foreign_key: true, type: :uuid

      # --- Request ---
      t.integer  :request_type, null: false, default: 0
      t.integer  :status, null: false, default: 0
      t.datetime :requested_at
      t.datetime :completed_at
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

    add_index :data_subject_requests, [ :company_id, :status ]
  end
end
