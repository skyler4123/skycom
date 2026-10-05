class CreateEventConfigLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :event_config_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :event_config, null: true, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: true, foreign_key: true, type: :uuid
      t.integer :action, null: false
      t.string :employee_name
      t.string :category_name
      t.boolean :create_stock_pending
      t.boolean :strict_stock_hold
      t.boolean :create_order_on_complete
      t.boolean :warn_on_facility_overlap
      t.boolean :warn_on_host_overlap
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :event_config_logs, [ :company_id, :event_config_id, :created_at ],
      name: "idx_event_config_logs_on_config_time"
    add_index :event_config_logs, [ :company_id, :created_at ],
      name: "idx_event_config_logs_on_company_time"
  end
end
