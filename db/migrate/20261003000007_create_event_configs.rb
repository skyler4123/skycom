class CreateEventConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :event_configs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.boolean :create_stock_pending, null: false, default: false
      t.boolean :strict_stock_hold, null: false, default: false
      t.boolean :create_order_on_complete, null: false, default: false
      t.boolean :warn_on_facility_overlap, null: false, default: true
      t.boolean :warn_on_host_overlap, null: false, default: true
      t.string :name
      t.string :description
      t.string :code

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
    add_index :event_configs, [ :company_id, :category_id ], unique: true, name: "idx_event_configs_company_category_uniq"
  end
end
