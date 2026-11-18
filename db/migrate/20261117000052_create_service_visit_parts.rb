class CreateServiceVisitParts < ActiveRecord::Migration[8.0]
  def change
    create_table :service_visit_parts, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :service_visit, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.references :stock, foreign_key: true, type: :uuid

      # --- Part ---
      t.integer :quantity, null: false, default: 1
      t.bigint  :price_cents, null: false, default: 0
      t.integer :currency, default: 840

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

    add_index :service_visit_parts, [ :service_visit_id, :product_id ]
  end
end
