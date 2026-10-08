class CreatePermissionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :permission_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :policy, null: true, foreign_key: true, type: :uuid
      t.references :role, null: true, foreign_key: true, type: :uuid
      t.references :policy_role_appointment, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: true, foreign_key: true, type: :uuid

      t.integer :action, null: false
      t.string :employee_name
      t.string :role_name
      t.string :policy_name
      t.string :resource_name
      t.string :policy_action
      t.integer :from_workflow_status
      t.integer :to_workflow_status

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :permission_logs, [ :company_id, :created_at ]
    add_index :permission_logs, [ :company_id, :role_id, :created_at ], name: "idx_permission_logs_on_company_role_time"
    add_index :permission_logs, [ :company_id, :policy_id, :created_at ], name: "idx_permission_logs_on_company_policy_time"
  end
end
