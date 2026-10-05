class CreateTableConfigLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :table_config_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :table_config, null: true, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.references :property_mapping, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: true, foreign_key: true, type: :uuid
      t.integer :action, null: false
      t.string :employee_name
      t.string :category_name
      t.string :property_mapping_name
      t.string :name
      t.string :description
      t.string :resource_name
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :table_config_logs, [ :company_id, :table_config_id, :created_at ],
      name: "idx_table_config_logs_on_config_time"
    add_index :table_config_logs, [ :company_id, :created_at ],
      name: "idx_table_config_logs_on_company_time"
  end
end
