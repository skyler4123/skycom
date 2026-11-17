class CreatePickWaves < ActiveRecord::Migration[8.0]
  def change
    create_table :pick_waves, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :created_by_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Wave ---
      t.string   :name, null: false
      t.integer  :status, null: false, default: 0
      t.datetime :released_at
      t.datetime :completed_at

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

    add_index :pick_waves, [ :company_id, :status ]
    add_index :pick_waves, [ :warehouse_id, :created_at ]
  end
end
