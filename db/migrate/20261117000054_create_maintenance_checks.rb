class CreateMaintenanceChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_checks, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :maintenance_plan, null: false, foreign_key: true, type: :uuid

      # --- Check ---
      t.string  :name, null: false
      t.text    :instruction
      t.integer :position, null: false, default: 1
      t.boolean :is_required, null: false, default: true

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

    add_index :maintenance_checks, [ :maintenance_plan_id, :position ], unique: true
  end
end
