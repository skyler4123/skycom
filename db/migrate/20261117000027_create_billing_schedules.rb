class CreateBillingSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_schedules, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :subscription_group, null: false, foreign_key: true, type: :uuid, index: { unique: true }

      # --- Schedule ---
      t.integer  :interval, null: false, default: 1
      t.integer  :interval_count, null: false, default: 1
      t.date     :next_run_on, null: false
      t.date     :last_run_on
      t.integer  :status, null: false, default: 0
      t.datetime :canceled_at

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

    add_index :billing_schedules, [ :company_id, :next_run_on ]
  end
end
