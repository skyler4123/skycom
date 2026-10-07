class CreateNotificationConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_configs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.datetime :last_read_all_at
      t.jsonb :preferences, default: {}

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

    add_index :notification_configs, [ :company_id, :employee_id ], unique: true,
      name: "idx_notif_configs_on_company_emp"
  end
end
