class CreateWorkflowStepLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :workflow_step_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :workflow, null: false, foreign_key: true, type: :uuid
      t.references :workflow_step, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: true, foreign_key: { to_table: :employees }, type: :uuid
      t.references :subject, polymorphic: true, null: false, type: :uuid
      t.integer :outcome
      t.text :note

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

    add_index :workflow_step_logs, [ :workflow_id, :workflow_step_id ]
    add_index :workflow_step_logs, [ :workflow_id, :created_at ]
  end
end
