class CreateMaintenancePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_plans, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :facility, foreign_key: true, type: :uuid
      t.references :fixed_asset, foreign_key: true, type: :uuid

      # --- Plan ---
      t.string  :name, null: false
      t.integer :interval_days
      t.integer :interval_usage
      t.date    :next_due_on
      t.date    :last_done_on
      t.integer :status, null: false, default: 0

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

    add_index :maintenance_plans, [ :company_id, :next_due_on ]
  end
end
