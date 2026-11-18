class CreateWorkCenters < ActiveRecord::Migration[8.0]
  def change
    create_table :work_centers, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid

      # --- Resource ---
      t.string  :name, null: false
      t.decimal :capacity_per_hour, precision: 15, scale: 4, null: false, default: 1.0
      t.bigint  :cost_per_hour_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.boolean :is_active, null: false, default: true

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

    add_index :work_centers, [ :company_id, :name ], unique: true
  end
end
