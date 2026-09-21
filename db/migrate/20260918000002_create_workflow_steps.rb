class CreateWorkflowSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :workflow_steps, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :workflow, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.integer :position

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

    add_index :workflow_steps, [ :workflow_id, :position ]
  end
end
