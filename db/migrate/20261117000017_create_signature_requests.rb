class CreateSignatureRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_requests, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :document, foreign_key: true, type: :uuid
      t.references :stored_file, foreign_key: true, type: :uuid
      t.references :requested_by_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Request ---
      t.integer  :status, null: false, default: 0
      t.text     :message
      t.datetime :expires_at
      t.datetime :completed_at

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

    add_index :signature_requests, [ :company_id, :status ]
  end
end
