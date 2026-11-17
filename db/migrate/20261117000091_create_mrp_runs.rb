class CreateMrpRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :mrp_runs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Run ---
      t.date     :run_on, null: false
      t.integer  :horizon_days, null: false, default: 30
      t.integer  :status, null: false, default: 0
      t.jsonb    :parameters, default: {}
      t.datetime :completed_at
      t.text     :error_message

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

    add_index :mrp_runs, [ :company_id, :run_on ]
  end
end
